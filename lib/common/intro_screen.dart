import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:snippet/features/auth/view/signup_view.dart';
import 'package:snippet/theme/pallete.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({Key? key}) : super(key: key);

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  late AnimationController _animationController;
  late Animation<double> _animation;
  int _currentPage = 0;

  final List<IntroSlide> _slides = [
    IntroSlide(
      title: "See what's happening",
      description: "Join Snippet today and dive into what's trending right now.",
      imagePath: 'assets/svgs/twitter_feed.svg',
      backgroundColor: Colors.white,
    ),
    IntroSlide(
      title: "Join the conversation",
      description: "Follow your interests and hear what people are talking about.",
      imagePath: 'assets/svgs/twitter_conversation.svg',
      backgroundColor: Colors.white,
    ),
    IntroSlide(
      title: "Make it yours",
      description: "Customize your profile, follow topics you care about, and join the conversation.",
      imagePath: 'assets/svgs/twitter_profile.svg',
      backgroundColor: Colors.white,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onNextPage() {
    if (_currentPage < _slides.length - 1) {
      _animationController.reset();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
      _animationController.forward();
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SignUpView()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Main content area
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                  _animationController.reset();
                  _animationController.forward();
                },
                itemBuilder: (context, index) {
                  return _buildSlide(_slides[index]);
                },
              ),
            ),
            
            // Page indicators
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _slides.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index ? Pallete.blueColor : Pallete.greyColor.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
            
            // Bottom action buttons
            Padding(
              padding: const EdgeInsets.only(left: 24.0, right: 24.0, bottom: 40.0),
              child: Column(
                children: [
                  // Create account button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _onNextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Pallete.blueColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        _currentPage == _slides.length - 1 ? "Get started" : "Next",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Log in link
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => const SignUpView()),
                      );
                    },
                    child: RichText(
                      text: TextSpan(
                        text: "Have an account already? ",
                        style: TextStyle(color: Colors.black.withOpacity(0.7), fontSize: 14),
                        children: [
                          TextSpan(
                            text: "Log in",
                            style: TextStyle(
                              color: Pallete.blueColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide(IntroSlide slide) {
    return FadeTransition(
      opacity: _animation,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Image illustration
            SvgPicture.asset(
              slide.imagePath,
              height: 240,
            ),
            
            const SizedBox(height: 40),
            
            // Title
            Text(
              slide.title,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 16),
            
            // Description
            Text(
              slide.description,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black.withOpacity(0.6),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class IntroSlide {
  final String title;
  final String description;
  final String imagePath;
  final Color backgroundColor;

  IntroSlide({
    required this.title,
    required this.description,
    required this.imagePath,
    required this.backgroundColor,
  });
}
