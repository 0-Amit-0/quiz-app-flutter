import 'dart:async'; // For the timer
import 'dart:convert'; // For parsing JSON
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // For API calls
import 'package:shared_preferences/shared_preferences.dart'; // For high score

// Main function to run the app
void main() {
  runApp(const QuizApp());
}

// The root widget of the application
class QuizApp extends StatelessWidget {
  const QuizApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'General Knowledge Quiz',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF111827), // gray-900
        primaryColor: const Color(0xFF8B5CF6), // violet-500
        fontFamily: 'Inter',
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF8B5CF6), // violet-500
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'Inter',
            ),
          ),
        ),
      ),
      home: const QuizScreen(),
    );
  }
}

// Data model for a single question
class Question {
  final String questionText;
  final List<Answer> answers;

  Question({required this.questionText, required this.answers});
}

// Data model for an answer
class Answer {
  final String text;
  final bool isCorrect;

  Answer({required this.text, required this.isCorrect});
}

// Represents the different screens/states of the app
enum GameState { start, loading, playing, results }

// The main screen widget, which manages the state of the quiz
class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

// The state class for the QuizScreen
class _QuizScreenState extends State<QuizScreen> {
  // --- STATE VARIABLES ---
  GameState _gameState = GameState.start;
  int _currentQuestionIndex = 0;
  int _score = 0;
  List<Question> _shuffledQuestions = [];
  Answer? _selectedAnswer;

  // --- CATEGORY & DIFFICULTY VARIABLES ---
  final Map<String, int> _categories = {
    "General Knowledge": 9,
    "Entertainment: Books": 10,
    "Entertainment: Film": 11,
    "Entertainment: Music": 12,
    "Science & Nature": 17,
    "Science: Computers": 18,
    "Sports": 21,
    "Geography": 22,
    "History": 23,
    "Politics": 24,
    "Art": 25,
  };
  final Map<String, String> _difficultyLevels = {
    "Easy": "easy",
    "Medium": "medium",
    "Hard": "hard",
  };
  String? _selectedCategory;
  String? _selectedDifficulty;

  // --- HIGH SCORE VARIABLES ---
  int _highScore = 0;

  // --- TIMER VARIABLES ---
  static const int _questionTimeInSeconds = 15;
  Timer? _timer;
  int _timeRemaining = _questionTimeInSeconds;

  // --- LIFECYCLE METHODS ---

  @override
  void initState() {
    super.initState();
    _loadHighScore(); // Load the high score when the app starts
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancel the timer if the widget is removed
    super.dispose();
  }

  // --- UI BUILDING METHODS ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1F2937), // gray-800
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF374151)), // gray-700
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _buildCurrentScreen(),
            ),
          ),
        ),
      ),
    );
  }

  // Determines which screen to show based on the current game state
  Widget _buildCurrentScreen() {
    switch (_gameState) {
      case GameState.start:
        return _buildStartScreen();
      case GameState.loading:
        return Column(
          mainAxisSize: MainAxisSize.min,
          key: const ValueKey('loading'),
          children: const [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text("Loading questions..."),
          ],
        );
      case GameState.playing:
        return _buildQuizScreen();
      case GameState.results:
        return _buildResultsScreen();
    }
  }

  // Builds the initial start screen
  Widget _buildStartScreen() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      key: const ValueKey('start'),
      children: [
        const Text(
          "General Knowledge Quiz",
          style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFFA78BFA)), // violet-400
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        // HIGH SCORE DISPLAY
        Text(
          "High Score: $_highScore",
          style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.white70),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        // CATEGORY DROPDOWN
        _buildDropdown(
          hint: "Select a category",
          value: _selectedCategory,
          items: _categories.keys.toList(),
          onChanged: (newValue) {
            setState(() {
              _selectedCategory = newValue;
            });
          },
        ),
        const SizedBox(height: 16),
        // DIFFICULTY DROPDOWN
        _buildDropdown(
          hint: "Select difficulty",
          value: _selectedDifficulty,
          items: _difficultyLevels.keys.toList(),
          onChanged: (newValue) {
            setState(() {
              _selectedDifficulty = newValue;
            });
          },
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            // Button is disabled if either option is not selected
            onPressed:
                (_selectedCategory != null && _selectedDifficulty != null)
                    ? _startQuiz
                    : null,
            child: const Text("Start Quiz"),
          ),
        ),
      ],
    );
  }

  // Helper widget for dropdowns
  Widget _buildDropdown(
      {required String hint,
      String? value,
      required List<String> items,
      required ValueChanged<String?> onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        hint: Text(hint),
        underline: const SizedBox(), // Removes the default underline
        style: const TextStyle(color: Colors.white, fontSize: 16),
        dropdownColor: Colors.grey[800],
        onChanged: onChanged,
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(item),
          );
        }).toList(),
      ),
    );
  }

  // Builds the main quiz interface
  Widget _buildQuizScreen() {
    if (_shuffledQuestions.isEmpty) {
      return const Center(child: Text("Failed to load questions."));
    }

    final currentQuestion = _shuffledQuestions[_currentQuestionIndex];
    return Column(
      mainAxisSize: MainAxisSize.min,
      key: ValueKey('question_$_currentQuestionIndex'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildProgressIndicator(),
        const SizedBox(height: 16),
        // TIMER BAR
        _buildTimerIndicator(),
        const SizedBox(height: 24),
        SizedBox(
          height: 100, // min height for question text
          child: Text(
            // The API can return HTML entities, this is a basic way to clean them
            _cleanText(currentQuestion.questionText),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 24),
        ...currentQuestion.answers.map((answer) => _buildAnswerButton(answer)),
        const SizedBox(height: 24),
        if (_selectedAnswer != null)
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _nextQuestion,
              style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.grey[700]),
              child: const Text("Next"),
            ),
          ),
      ],
    );
  }

  // Builds the final results screen
  Widget _buildResultsScreen() {
    // Check for new high score
    bool isNewHighScore = _score > _highScore;
    if (isNewHighScore) {
      _saveHighScore(_score);
      _highScore = _score;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      key: const ValueKey('results'),
      children: [
        const Text(
          "Quiz Complete!",
          style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFFA78BFA)),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        // NEW HIGH SCORE TEXT
        if (isNewHighScore)
          const Text(
            "🎉 New High Score! 🎉",
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.amber),
            textAlign: TextAlign.center,
          ),
        if (isNewHighScore) const SizedBox(height: 24),
        Text(
          "Your final score is",
          style: TextStyle(fontSize: 20, color: Colors.grey[300]),
        ),
        const SizedBox(height: 8),
        Text(
          "$_score / ${_shuffledQuestions.length}",
          style: const TextStyle(fontSize: 60, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _returnToStart,
            child: const Text("Play Again"),
          ),
        ),
      ],
    );
  }

  // --- HELPER WIDGETS ---

  // Shows Question X of Y and Score
  Widget _buildProgressIndicator() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Question ${_currentQuestionIndex + 1} of ${_shuffledQuestions.length}",
              style: TextStyle(color: Colors.grey[400]),
            ),
            Text(
              "Score: $_score",
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Color(0xFFA78BFA)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: (_currentQuestionIndex + 1) / _shuffledQuestions.length,
            minHeight: 10,
            backgroundColor: Colors.grey[800],
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF8B5CF6)),
          ),
        ),
      ],
    );
  }

  // Shows the 15-second countdown timer
  Widget _buildTimerIndicator() {
    double timerPercentage = _timeRemaining / _questionTimeInSeconds;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Time remaining: $_timeRemaining",
          style: TextStyle(color: Colors.grey[400]),
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: timerPercentage,
            minHeight: 10,
            backgroundColor: Colors.grey[800],
            valueColor: AlwaysStoppedAnimation<Color>(
                timerPercentage > 0.5
                    ? Colors.green
                    : timerPercentage > 0.25
                        ? Colors.orange
                        : Colors.red),
          ),
        ),
      ],
    );
  }

  Widget _buildAnswerButton(Answer answer) {
    bool isSelected = _selectedAnswer == answer;
    Color? buttonColor;
    Color borderColor = Colors.grey[600]!;

    if (_selectedAnswer != null) {
      if (answer.isCorrect) {
        buttonColor = Colors.green[500];
        borderColor = Colors.green[600]!;
      } else if (isSelected) {
        buttonColor = Colors.red[500];
        borderColor = Colors.red[600]!;
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: _selectedAnswer == null ? () => _selectAnswer(answer) : null,
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: buttonColor,
            side: BorderSide(color: borderColor, width: 2),
            padding: const EdgeInsets.all(16),
            alignment: Alignment.centerLeft,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(
            _cleanText(answer.text),
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }

  // --- LOGIC METHODS ---

  // Function to fetch questions from the API
  Future<void> _fetchQuestions() async {
    final categoryId = _categories[_selectedCategory!];
    final difficulty = _difficultyLevels[_selectedDifficulty!];

    final url = Uri.parse(
        'https://opentdb.com/api.php?amount=10&category=$categoryId&difficulty=$difficulty&type=multiple');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;

        // Check if API returned questions
        if (results.isEmpty) {
          // No questions found, e.g., for a specific category/difficulty combo
          _showErrorAndReset("No questions found for this selection.");
          return;
        }

        final newQuestions = results.map((q) {
          List<Answer> answers = [
            ...List<String>.from(q['incorrect_answers'])
                .map((a) => Answer(text: a, isCorrect: false)),
            Answer(text: q['correct_answer'], isCorrect: true),
          ];
          answers.shuffle();

          return Question(
            questionText: q['question'],
            answers: answers,
          );
        }).toList();

        setState(() {
          _shuffledQuestions = newQuestions;
          _gameState = GameState.playing; // Start the game
        });
        _startTimer(); // Start the timer for the first question
      } else {
        _showErrorAndReset("Failed to load questions from server.");
      }
    } catch (e) {
      _showErrorAndReset("Failed to connect. Check your internet.");
      print("Error fetching questions: $e");
    }
  }

  // Starts the quiz
  void _startQuiz() {
    setState(() {
      _gameState = GameState.loading;
      _currentQuestionIndex = 0;
      _score = 0;
      _selectedAnswer = null;
      _shuffledQuestions = [];
    });
    _fetchQuestions();
  }

  // Handles selecting an answer
  void _selectAnswer(Answer? answer) {
    _cancelTimer(); // Stop the timer
    setState(() {
      _selectedAnswer = answer ??
          Answer(
              text: "No Answer",
              isCorrect: false); // Handle timer running out
      if (answer != null && answer.isCorrect) {
        _score++;
      }
    });
  }

  // Moves to the next question or to the results screen
  void _nextQuestion() {
    if (_currentQuestionIndex < _shuffledQuestions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _selectedAnswer = null;
      });
      _startTimer(); // Start timer for the next question
    } else {
      // Last question, go to results
      setState(() {
        _gameState = GameState.results;
      });
    }
  }

  // Resets the app to the start screen
  void _returnToStart() {
    setState(() {
      _gameState = GameState.start;
      _selectedCategory = null;
      _selectedDifficulty = null;
      _shuffledQuestions = [];
    });
  }

  // --- TIMER METHODS ---

  void _startTimer() {
    _cancelTimer(); // Ensure any existing timer is cancelled
    _timeRemaining = _questionTimeInSeconds;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeRemaining > 0) {
          _timeRemaining--;
        } else {
          _selectAnswer(null); // Time's up!
          timer.cancel();
        }
      });
    });
  }

  void _cancelTimer() {
    _timer?.cancel();
  }

  // --- HIGH SCORE METHODS ---

  Future<void> _loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _highScore = prefs.getInt('highScore') ?? 0;
    });
  }

  Future<void> _saveHighScore(int newScore) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('highScore', newScore);
  }

  // --- UTILITY METHODS ---

  // Cleans HTML entities from API text
  String _cleanText(String text) {
    return text
        .replaceAll('&quot;', '"')
        .replaceAll('&#039;', "'")
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&ouml;', 'ö');
  }

  // Handles API or connection errors
  void _showErrorAndReset(String message) {
    setState(() {
      _gameState = GameState.start; // Go back to start screen
    });
    // Show a snackbar with the error
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}