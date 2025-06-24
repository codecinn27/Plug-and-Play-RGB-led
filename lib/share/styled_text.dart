import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class StyledText extends StatelessWidget {
  const StyledText(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, 
    style: GoogleFonts.kanit(
      textStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontSize: 24, // Increase font size
        ),
    ));
    }
}

class StyledTextRegular extends StatelessWidget {
  const StyledTextRegular(this.text, this.size, {super.key});

  final String text;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: size
      ) 
    );
  }
}


class StyledHeading extends StatelessWidget {
  const StyledHeading(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text.toUpperCase(), 
    style: GoogleFonts.kanit(
      textStyle: Theme.of(context).textTheme.headlineMedium?.copyWith(
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w500, // semi-bold
        ),
    ));
  }
}


const TextStyle boldWhiteText = TextStyle(
  fontSize: 16,
  fontWeight: FontWeight.bold,
  color: Colors.white,
);