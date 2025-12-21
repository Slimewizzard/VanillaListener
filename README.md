# VanillaListener

VanillaListener is a World of Warcraft (1.12.1) addon designed to help you track chat messages (/say, /yell, /emote) from specific players. It provides a persistent history of messages and a consolidated view to monitor multiple players at once.

## Features

- **Player Tracking**: Easily add players to your tracking list by name or by targeting them.
- **Message History**: Stores the last 20 messages for each tracked player.
- **"All Tracked" View**: A dedicated view showing the last 50 chronological messages from *all* tracked players combined.
- **Auto-Update**: The history window updates in real-time as new messages arrive.
- **Independent Windows**:
  - **Main Window**: Manage your tracked players list.
  - **History Window**: View messages in a dedicated, resizable window.
- **Customizable UI**:
  - Both windows are movable and resizable (with memory).
  - Adjustable text size for the message history.

## Usage

### Commands
- **/vl** or **/listener**: Toggles the Main Window.

### Main Window
- **Add Player**: Type a character name in the box and click "Add". logic:
  - If the box is empty and you have a player targeted, clicking "Add" will add your target.
- **Player List**:
  - Click a player's name to open their specific history.
  - Click "All Tracked" to view the combined history.
  - Click the small **X** next to a name to stop tracking that player.
- **Resize**: Drag the bottom-right corner to resize the window.
- **Text Size**: Use the **+** and **-** buttons in the bottom-left corner to adjust the font size of the History Window.

### History Window
- Displays messages with timestamps.
- **Resize**: Drag the bottom-right corner to resize the window. The text will automatically re-wrap to fit.
- **Scrolling**: Use the scroll bar to view older messages. The window auto-scrolls to the bottom when new messages arrive.

## Installation

1. Place the `VanillaListener` folder into your `Interface\AddOns\` directory.
2. Launch WoW and enable the addon at the character selection screen.
