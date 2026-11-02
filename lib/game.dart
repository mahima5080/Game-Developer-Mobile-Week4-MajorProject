import 'dart:async';
import 'dart:math';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CapstoneGame extends FlameGame with TapCallbacks {
  // Player Attributes
  late Vector2 playerPos;
  late Vector2 playerVel;
  final Vector2 playerSize = Vector2(30, 38);
  bool isGrounded = false;
  int lives = 3;
  int score = 0;
  int highScore = 0;
  int currentLevel = 1;

  // Power-Up Buffs
  bool isShieldActive = false;
  double shieldTimer = 0.0;
  int scoreMultiplier = 1;
  double multiplierTimer = 0.0;

  // Game States
  bool isGameOver = false;
  bool isGameWon = false;

  // Physics
  final double gravity = 900.0;
  final double moveSpeed = 210.0;
  final double jumpForce = -430.0;
  double horizontalInput = 0.0;

  // World Entities
  List<Rect> levelPlatforms = [];
  List<PowerUp> powerUps = [];
  List<Rect> coins = [];
  late Rect levelGoal;
  List<GameEnemy> enemies = [];

  final Random random = Random();

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await loadHighScore();
    loadLevel(1);
  }

  // ---------------------------------------------------------------------------
  // HIGH SCORE PERSISTENCE STORAGE
  // ---------------------------------------------------------------------------
  Future<void> loadHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    highScore = prefs.getInt('capstone_high_score') ?? 0;
  }

  Future<void> saveHighScore() async {
    if (score > highScore) {
      highScore = score;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('capstone_high_score', highScore);
    }
  }

  // ---------------------------------------------------------------------------
  // 3-LEVEL DESIGN & PROCEDURAL SETUP
  // ---------------------------------------------------------------------------
  void loadLevel(int level) {
    currentLevel = level;
    horizontalInput = 0.0;
    isShieldActive = false;
    scoreMultiplier = 1;
    playerPos = Vector2(40, size.y - 120);
    playerVel = Vector2.zero();

    coins.clear();
    powerUps.clear();
    enemies.clear();

    if (level == 1) {
      // LEVEL 1: Grassland Beginner
      levelPlatforms = [
        Rect.fromLTWH(0, size.y - 40, size.x, 40),
        Rect.fromLTWH(60, size.y - 140, 110, 20),
        Rect.fromLTWH(200, size.y - 220, 120, 20),
        Rect.fromLTWH(size.x - 140, size.y - 150, 100, 20),
      ];
      coins = [
        Rect.fromLTWH(100, size.y - 180, 18, 18),
        Rect.fromLTWH(250, size.y - 260, 18, 18),
      ];
      powerUps.add(PowerUp(pos: Vector2(210, size.y - 260), type: PowerUpType.shield));
      enemies.add(GameEnemy(pos: Vector2(210, size.y - 250), size: Vector2(26, 26), minX: 200, maxX: 300, speed: 80));
      levelGoal = Rect.fromLTWH(size.x - 80, size.y - 210, 30, 60);

    } else if (level == 2) {
      // LEVEL 2: Desert Intermediate
      levelPlatforms = [
        Rect.fromLTWH(0, size.y - 40, 120, 40),
        Rect.fromLTWH(150, size.y - 130, 100, 20),
        Rect.fromLTWH(40, size.y - 230, 110, 20),
        Rect.fromLTWH(200, size.y - 310, 130, 20),
        Rect.fromLTWH(size.x - 130, size.y - 160, 110, 20),
      ];
      coins = [
        Rect.fromLTWH(180, size.y - 170, 18, 18),
        Rect.fromLTWH(80, size.y - 270, 18, 18),
        Rect.fromLTWH(250, size.y - 350, 18, 18),
      ];
      powerUps.add(PowerUp(pos: Vector2(90, size.y - 270), type: PowerUpType.doubleScore));
      enemies.add(GameEnemy(pos: Vector2(50, size.y - 260), size: Vector2(26, 26), minX: 40, maxX: 130, speed: 110));
      enemies.add(GameEnemy(pos: Vector2(210, size.y - 340), size: Vector2(26, 26), minX: 200, maxX: 310, speed: 100));
      levelGoal = Rect.fromLTWH(size.x - 80, size.y - 220, 30, 60);

    } else if (level == 3) {
      // LEVEL 3: Volcanic Hard Capstone
      levelPlatforms = [
        Rect.fromLTWH(0, size.y - 40, 90, 40),
        Rect.fromLTWH(130, size.y - 120, 90, 20),
        Rect.fromLTWH(250, size.y - 200, 90, 20),
        Rect.fromLTWH(110, size.y - 290, 100, 20),
        Rect.fromLTWH(size.x - 120, size.y - 350, 100, 20),
      ];
      coins = [
        Rect.fromLTWH(160, size.y - 160, 18, 18),
        Rect.fromLTWH(280, size.y - 240, 18, 18),
        Rect.fromLTWH(140, size.y - 330, 18, 18),
      ];
      powerUps.add(PowerUp(pos: Vector2(270, size.y - 240), type: PowerUpType.shield));
      enemies.add(GameEnemy(pos: Vector2(140, size.y - 150), size: Vector2(26, 26), minX: 130, maxX: 210, speed: 130));
      enemies.add(GameEnemy(pos: Vector2(120, size.y - 320), size: Vector2(26, 26), minX: 110, maxX: 200, speed: 140));
      levelGoal = Rect.fromLTWH(size.x - 80, size.y - 410, 30, 60);
    }
  }

  void resetGame() {
    score = 0;
    lives = 3;
    isGameOver = false;
    isGameWon = false;
    loadLevel(1);
  }

  // ---------------------------------------------------------------------------
  // INPUT & TOUCH CONTROLS
  // ---------------------------------------------------------------------------
  @override
  void onTapDown(TapDownEvent event) {
    if (isGameOver || isGameWon) {
      resetGame();
      return;
    }

    final tapPos = event.canvasPosition;

    if (tapPos.y > size.y - 90) {
      if (tapPos.x < 90) {
        horizontalInput = -1.0;
      } else if (tapPos.x > 100 && tapPos.x < 190) {
        horizontalInput = 1.0;
      } else if (tapPos.x > size.x - 110 && isGrounded) {
        playerVel.y = jumpForce;
        isGrounded = false;
      }
    } else if (isGrounded) {
      playerVel.y = jumpForce;
      isGrounded = false;
    }
  }

  @override
  void onTapUp(TapUpEvent event) {
    horizontalInput = 0.0;
  }

  // ---------------------------------------------------------------------------
  // UPDATE LOOP & POWER-UP TIMERS
  // ---------------------------------------------------------------------------
  @override
  void update(double dt) {
    super.update(dt);
    if (isGameOver || isGameWon) return;

    // Power-up Buff Timers
    if (isShieldActive) {
      shieldTimer -= dt;
      if (shieldTimer <= 0) isShieldActive = false;
    }
    if (scoreMultiplier > 1) {
      multiplierTimer -= dt;
      if (multiplierTimer <= 0) scoreMultiplier = 1;
    }

    // Update Enemies
    for (final enemy in enemies) {
      enemy.update(dt);
    }

    // Velocity & Gravity Updates
    playerVel.x = horizontalInput * moveSpeed;
    playerVel.y += gravity * dt;

    playerPos.x += playerVel.x * dt;
    playerPos.x = playerPos.x.clamp(0.0, size.x - playerSize.x);

    playerPos.y += playerVel.y * dt;

    // Platform Physics
    isGrounded = false;
    final Rect playerRect = Rect.fromLTWH(playerPos.x, playerPos.y, playerSize.x, playerSize.y);

    for (final platform in levelPlatforms) {
      if (playerRect.overlaps(platform) &&
          playerVel.y > 0 &&
          (playerPos.y + playerSize.y - playerVel.y * dt) <= platform.top + 10) {
        playerPos.y = platform.top - playerSize.y;
        playerVel.y = 0;
        isGrounded = true;
      }
    }

    // Coin Pickups
    for (int i = coins.length - 1; i >= 0; i--) {
      if (playerRect.overlaps(coins[i])) {
        coins.removeAt(i);
        score += 50 * scoreMultiplier;
        saveHighScore();
      }
    }

    // Power-Up Pickups
    for (int i = powerUps.length - 1; i >= 0; i--) {
      if (playerRect.overlaps(powerUps[i].rect)) {
        if (powerUps[i].type == PowerUpType.shield) {
          isShieldActive = true;
          shieldTimer = 5.0; // 5-second invincibility shield
        } else if (powerUps[i].type == PowerUpType.doubleScore) {
          scoreMultiplier = 2;
          multiplierTimer = 8.0; // 8-second 2x score multiplier
        }
        powerUps.removeAt(i);
      }
    }

    // Enemy Collisions
    for (final enemy in enemies) {
      if (playerRect.overlaps(enemy.rect)) {
        if (!isShieldActive) {
          lives--;
          if (lives <= 0) {
            isGameOver = true;
            saveHighScore();
          } else {
            playerPos = Vector2(40, size.y - 120);
            playerVel = Vector2.zero();
          }
        }
      }
    }

    // Goal Endpoint Collision (Advance to Next Level or Win)
    if (playerRect.overlaps(levelGoal)) {
      if (currentLevel < 3) {
        loadLevel(currentLevel + 1);
      } else {
        isGameWon = true;
        saveHighScore();
      }
    }

    // Fall Off Boundary
    if (playerPos.y > size.y) {
      lives--;
      if (lives <= 0) {
        isGameOver = true;
        saveHighScore();
      } else {
        playerPos = Vector2(40, size.y - 120);
        playerVel = Vector2.zero();
      }
    }
  }

  // ---------------------------------------------------------------------------
  // RENDERING & HUD OVERLAYS
  // ---------------------------------------------------------------------------
  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // 1. Draw Platforms
    final Paint platPaint = Paint()
      ..color = currentLevel == 1
          ? const Color(0xFF15803D)
          : (currentLevel == 2 ? const Color(0xFFD97706) : const Color(0xFFB91C1C));
    for (final plat in levelPlatforms) {
      canvas.drawRRect(RRect.fromRectAndRadius(plat, const Radius.circular(4)), platPaint);
    }

    // 2. Draw Coins
    final Paint coinPaint = Paint()..color = const Color(0xFFFBBF24);
    for (final coin in coins) {
      canvas.drawCircle(coin.center, coin.width / 2, coinPaint);
    }

    // 3. Draw Power-Ups
    for (final pu in powerUps) {
      final Paint puPaint = Paint()..color = pu.type == PowerUpType.shield ? const Color(0xFF38BDF8) : const Color(0xFFA855F7);
      canvas.drawRRect(RRect.fromRectAndRadius(pu.rect, const Radius.circular(6)), puPaint);
    }

    // 4. Draw Goal Flag
    final Paint flagPaint = Paint()..color = const Color(0xFF22C55E);
    canvas.drawRect(levelGoal, flagPaint);

    // 5. Draw Enemies
    final Paint enemyPaint = Paint()..color = const Color(0xFFEF4444);
    for (final enemy in enemies) {
      canvas.drawRect(enemy.rect, enemyPaint);
    }

    // 6. Draw Player Character & Shield Aura
    if (isShieldActive) {
      final Paint shieldPaint = Paint()..color = const Color(0xFF38BDF8).withOpacity(0.5);
      canvas.drawCircle(Offset(playerPos.x + playerSize.x / 2, playerPos.y + playerSize.y / 2), 26, shieldPaint);
    }

    final Paint playerPaint = Paint()..color = const Color(0xFF3B82F6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(playerPos.x, playerPos.y, playerSize.x, playerSize.y), const Radius.circular(6)),
      playerPaint,
    );

    // 7. Render Score & High Score HUD
    final TextPainter hudText = TextPainter(
      text: TextSpan(
        text: 'Lvl: $currentLevel  \vert{}  Score:$score  |  High: $highScore  \vert{}  Lives:${"❤️ " * lives}',
        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    );
    hudText.layout();
    hudText.paint(canvas, const Offset(15, 40));

    // Active Buffs HUD
    if (isShieldActive || scoreMultiplier > 1) {
      final String buffText = '${isShieldActive ? "🛡️ SHIELD " : ""}${scoreMultiplier > 1 ? "⚡ 2X MULTIPLIER" : ""}';
      final TextPainter buffDisplay = TextPainter(
        text: TextSpan(text: buffText, style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 14, fontWeight: FontWeight.bold)),
        textDirection: TextDirection.ltr,
      );
      buffDisplay.layout();
      buffDisplay.paint(canvas, const Offset(15, 65));
    }

    // 8. On-Screen Touch Buttons
    final Paint btnPaint = Paint()..color = Colors.white.withOpacity(0.2);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(15, size.y - 85, 65, 55), const Radius.circular(8)), btnPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(90, size.y - 85, 65, 55), const Radius.circular(8)), btnPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(size.x - 95, size.y - 85, 75, 55), const Radius.circular(8)), btnPaint);

    // 9. Overlay Screens (Victory / Game Over)
    if (isGameOver || isGameWon) {
      final Paint overlayPaint = Paint()..color = Colors.black.withOpacity(0.85);
      canvas.drawRect(Rect.fromLTWH(0, 0, size.x, size.y), overlayPaint);

      final String title = isGameWon ? '🏆 YOU BEAT THE GAME! 🏆' : 'GAME OVER 💀';
      final Color color = isGameWon ? const Color(0xFF22C55E) : const Color(0xFFEF4444);

      final TextPainter statusText = TextPainter(
        text: TextSpan(
          text: '$title\nFinal Score: $score\nHigh Score:$highScore\n\nTap to Play Again',
          style: TextStyle(color: color, fontSize: 26, fontWeight: FontWeight.bold, height: 1.4),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      statusText.layout();
      statusText.paint(canvas, Offset((size.x - statusText.width) / 2, (size.y - statusText.height) / 2));
    }
  }
}

// -----------------------------------------------------------------------------
// ENEMY & POWERUP MODELS
// -----------------------------------------------------------------------------
class GameEnemy {
  Vector2 pos;
  Vector2 size;
  double minX;
  double maxX;
  double speed;

  GameEnemy({required this.pos, required this.size, required this.minX, required this.maxX, required this.speed});

  Rect get rect => Rect.fromLTWH(pos.x, pos.y, size.x, size.y);

  void update(double dt) {
    pos.x += speed * dt;
    if (pos.x <= minX) speed = speed.abs();
    if (pos.x >= maxX) speed = -speed.abs();
  }
}

enum PowerUpType { shield, doubleScore }

class PowerUp {
  Vector2 pos;
  PowerUpType type;
  PowerUp({required this.pos, required this.type});
  Rect get rect => Rect.fromLTWH(pos.x, pos.y, 20, 20);
}