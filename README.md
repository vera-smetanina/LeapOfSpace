# The Leap of Space

This is a SwiftUI science game based on the two game plans in the `docs` folder. It runs on iPhone, iPad, and Mac from one Xcode project.

Designed for the Oliphant Science Awards in Adelaide, South Australia.

The game already includes:

- all eight planets (Pluto is not included, just as the plan says)
- planet selection and gravity facts
- easy-to-hard science questions based on each planet's gravity
- multiple-choice and typed-answer screens
- forgiving spelling for typed answers
- loading, correct, incorrect, jump, fall, finish, and new-record screens
- the correct answer after an incorrect response
- a winning screen when every available question is answered correctly
- a separate timed leaderboard for every planet
- fastest-time ranking when two players have the same score
- buttons to retry a planet or go home

## 1. Open and play the game

1. Double-click `LeapOfSpace.xcodeproj`.
2. Near the top of Xcode, choose **LeapOfSpace** and then choose a device such as **My Mac**, an iPad simulator, or an iPhone simulator.
3. Press the triangular **Run** button.
4. Type a name, press **Play**, and choose a planet.

If Xcode asks for a development team, click the blue project icon, choose the **LeapOfSpace** target, open **Signing & Capabilities**, and choose your Apple ID team. A free Apple ID is enough for testing on your own iPhone or iPad.

## 2. Add or change questions

Open `LeapOfSpace/Questions.json` in Xcode. Each question looks like this:

```json
{
  "id": "my-question-1",
  "difficulty": 2,
  "prompt": "What is frozen water called?",
  "answerStyle": "text",
  "answers": ["ice"],
  "choices": null,
  "imageName": null,
  "hint": "It is very cold."
}
```

- Give every question a different `id`.
- Set `difficulty` from `1` (easiest) to `5` (hardest).
- For a typed answer, use `"answerStyle": "text"` and `"choices": null`.
- Put every accepted answer in `answers`. For example: `["Sun", "the Sun"]`.
- Small spelling mistakes are accepted automatically.
- Keep a comma between questions, but do not put a comma after the final question.

For multiple choice, use this shape:

```json
{
  "id": "my-question-2",
  "difficulty": 3,
  "prompt": "Which organ pumps blood?",
  "answerStyle": "multipleChoice",
  "answers": ["Heart"],
  "choices": ["Lungs", "Heart", "Brain", "Stomach"],
  "imageName": null,
  "hint": null
}
```

## 3. Add your own pictures

1. In Xcode, open `LeapOfSpace/Assets.xcassets`.
2. Drag a PNG or JPG picture into the big empty asset area. Xcode creates a new image set.
3. Give the image set a simple name, such as `question-volcano`. Names should not contain spaces.
4. In `Questions.json`, change `"imageName": null` to `"imageName": "question-volcano"`.
5. Run the game again.

The game works without custom pictures. It shows planets, an astronaut, and a science symbol as placeholders until her artwork is added.

### Replace a planet picture

Add an image to `Assets.xcassets` using one of these exact names:

`planet-mercury`, `planet-venus`, `planet-earth`, `planet-mars`, `planet-jupiter`, `planet-saturn`, `planet-uranus`, or `planet-neptune`.

Transparent PNG pictures work especially well. The game keeps the coloured planet circle behind the picture.

### Replace the astronaut

Add a transparent PNG image named `astronaut`. It will appear over the built-in astronaut placeholder.

## 4. Change a planet

Open `LeapOfSpace/Planets.json`. You can change its name, gravity fact, colours, difficulty, or image name.

Colours use six-character hex codes. Some examples are:

- `FFE347` = bright yellow
- `56A8FF` = bright blue
- `E77C45` = orange-red
- `43C66B` = green

Planet difficulty should stay between `1` and `5`. Stronger-gravity planets currently have harder questions, following the original game plan.

## 5. Change how a screen looks

The code is split up so each file has one clear job:

- `ContentView.swift` chooses which game screen is visible.
- `GameViews.swift` contains the buttons, text boxes, and layouts for every screen.
- `SpaceComponents.swift` contains reusable planets, stars, platforms, and button styles.
- `GameStore.swift` controls the game rules, timing, questions, streak, and leaderboard.
- `Models.swift` describes planets, questions, scores, and screens.

In Xcode, try changing one word or colour at a time, then press **Run** to see what happened. Xcode's Undo command is **Command-Z**, which makes experimenting much less scary.

## 6. Good next steps for the Science Awards entry

1. Draw or photograph original planet, astronaut, and question artwork and add it to the asset catalogue.
2. Write more questions at every difficulty level so repeat games stay surprising.
3. Check every science fact with a teacher or a trusted science source.
4. Ask friends to play without help and note anywhere they get confused.
5. Add an app icon by opening `AppIcon` inside `Assets.xcassets` and dropping in a square 1024 x 1024 image.
6. Keep the two original PDFs. They are excellent evidence of the design process from idea to working game.

## Privacy policy

This app collects no personal data. Your high scores are only saved on your own devices.
