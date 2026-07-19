# Games

One Swift package per game (plugin architecture, §4.3). Each package exposes a
type conforming to `TripGame` and registers it in `GameRegistry` from the app's
composition root. Content lives in `ContentKit` as locale × age-band JSON packs.

Stage 1 launch set (10): Smart Road Bingo, Cabin Bingo, 20 Questions,
Kids Trivia, Would You Rather, Finger & Face Charades, Forehead Guess,
Hot Potato Word Bomb, Secret Word, Trip Leaderboard & Rewards.
