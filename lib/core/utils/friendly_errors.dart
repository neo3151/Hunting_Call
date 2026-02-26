import 'dart:io';
import 'dart:async';
import 'package:flutter/services.dart';

class FriendlyErrorFormatter {
  /// Converts complex, technical exceptions into lighthearted, human-readable strings.
  static String format(dynamic error) {
    if (error == null) return "Oops, something went wrong. The squirrels are on it!";

    final errorString = error.toString().toLowerCase();

    // Network / Socket issues
    if (error is SocketException || errorString.contains('socket') || errorString.contains('network') || errorString.contains('xmlhttprequest')) {
      return "Oops, our servers took a coffee break! ☕ Please check your connection and try again.";
    }

    // Timeout
    if (error is TimeoutException || errorString.contains('timeout')) {
      return "Whoa, that took too long! The carrier pigeon must have gotten lost. 🐦";
    }

    // Platform / Plugin crashes
    if (error is PlatformException || errorString.contains('platform')) {
      return "Our gears got jammed for a second! ⚙️ Try giving it another tap.";
    }

    // Auth errors / Format issues
    if (error is FormatException || errorString.contains('format')) {
      return "Looks like we misread the map! 🗺️ We'll try to get back on track.";
    }

    if (errorString.contains('permission')) {
      return "Hold up! We don't have the key to open that door. 🗝️ Please check your app permissions.";
    }

    // Default friendly fallback
    return "A wild error appeared! 🦌 We're tracking it down as we speak.";
  }
}
