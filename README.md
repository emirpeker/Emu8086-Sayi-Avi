# 8086 Number Hunt | Sayı Avı

**8086 Assembly · emu8086 · BIOS Interrupts**

A text-mode number-collection game developed in **8086 Assembly**. The player moves around a bounded playfield, collects moving positive and negative numbers, and tries to reach the target score before time runs out.

> **Project scope:** An educational Assembly game designed for an 8086-compatible emulator. It is not a native Windows, macOS, or Linux application.

## Gameplay

- Control the player character (`P`) with the keyboard.
- Collect numbers to increase or decrease your score.
- Reach the target score to advance to the next round.
- Complete **five rounds** to win; the target score increases and the game speeds up as rounds progress.
- The game ends when time runs out.

### Controls

| Key | Action |
| --- | --- |
| `w` | Move up |
| `a` | Move left |
| `s` | Move down |
| `d` | Move right |
| `Esc` | Exit |

> **Note:** Movement is implemented with lowercase `w`, `a`, `s`, `d` key checks. Turn Caps Lock off while playing.

## Running the Game

1. Install or open **emu8086** on a supported environment.
2. Open `emu_sayi_avi.asm` in the emulator.
3. Assemble/compile and run the program.
4. Press any key to start, then use lowercase `w`, `a`, `s`, `d` to move.

The code is written as a `.COM`-style 8086 program (`org 100h`) and uses BIOS services. It requires a compatible emulator rather than a standard terminal.

## Implementation Details

- **Display:** BIOS `INT 10h` for 80×25 text mode, cursor positioning, character output, and colors.
- **Keyboard:** BIOS `INT 16h` for reading input.
- **Timing:** BIOS `INT 15h` to control game speed.
- **Randomization:** BIOS `INT 1Ah` clock data to generate new values after collection.
- **Game state:** Assembly variables and arrays for player position, moving numbers, speed, score, timer, and round progression.

## Repository Files

| File | Description |
| --- | --- |
| `emu_sayi_avi.asm` | Complete Assembly source code |
| `Emir-Peker-Sayi-Avi.pptx` | Project presentation |
| `EmirPeker_171424020.docx` | Project documentation |

## Limitations

- Timing depends on emulator and BIOS behavior; gameplay speed may vary across environments.
- The number-generation method is based on BIOS clock data, not a cryptographically secure random generator.
- The current implementation is intended for learning 8086 instructions, interrupts, and game-loop logic.

---

**Course project · Computer Engineering**
