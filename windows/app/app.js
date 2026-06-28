const app = document.querySelector("#app");

const delays = {
  selectedToGravity: 2000,
  readyToQuestion: 2200,
  checkingAnswer: 1400,
  correctResult: 1700,
  incorrectResult: 3000,
  movement: 1900,
  winner: 2600,
  finish: 1800
};

const state = {
  screen: "home",
  playerName: "",
  planets: [],
  questions: [],
  selectedPlanet: null,
  currentQuestion: null,
  usedQuestionIds: new Set(),
  typedAnswer: "",
  streak: 0,
  startedAt: null,
  finalTime: 0,
  scores: loadScores()
};

let questionTimer = null;

start();

async function start() {
  const [planets, questions] = await Promise.all([
    fetch("assets/data/planets.json").then((reply) => reply.json()),
    fetch("assets/data/questions.json").then((reply) => reply.json())
  ]);

  state.planets = planets;
  state.questions = questions;
  render();
}

function render() {
  app.innerHTML = `<div class="stars"></div>${screenHtml()}`;
  wireEvents();
}

function screenHtml() {
  if (state.screen === "home") return homeScreen();
  if (state.screen === "choosePlanet") return choosePlanetScreen();
  if (state.screen === "selected") return selectedScreen();
  if (state.screen === "gravity") return gravityScreen();
  if (state.screen === "astronaut") return astronautScreen("Ready for lift-off?", "idle");
  if (state.screen === "question") return questionScreen();
  if (state.screen === "answer") return answerScreen();
  if (state.screen === "loading") return messageScreen("Checking...");
  if (state.screen === "correct") return messageScreen("Correct!", "You leap upward.");
  if (state.screen === "incorrect") return incorrectScreen();
  if (state.screen === "movementUp") return astronautScreen("Higher and higher!", "up");
  if (state.screen === "movementDown") return astronautScreen("Back to the planet!", "down");
  if (state.screen === "winner") return messageScreen("You answered every question!", "Mission complete.");
  if (state.screen === "finish") return finishScreen();
  if (state.screen === "newRecord") return messageScreen("New record!", "Your score is going on the leaderboard.");
  if (state.screen === "leaderboard") return leaderboardScreen();
  return homeScreen();
}

function homeScreen() {
  return `
    <section class="screen">
      <div aria-hidden="true" style="font-size:58px;color:var(--gold)">&#10022;</div>
      <h1 class="title">THE LEAP<br>OF SPACE</h1>
      <div class="card name-box">
        <label class="label" for="playerName">SPACE EXPLORER NAME</label>
        <input class="text-input" id="playerName" value="${escapeHtml(state.playerName)}" placeholder="Type your name">
      </div>
      <button class="primary" data-action="play">PLAY</button>
      <p class="small-note">Science gets harder as gravity gets stronger</p>
    </section>
  `;
}

function choosePlanetScreen() {
  const groups = [
    { difficulty: 1, title: "EASY", subtitle: "Low gravity | Easy questions", color: "var(--green)" },
    { difficulty: 3, title: "MEDIUM", subtitle: "Medium gravity | Medium questions", color: "var(--cyan)" },
    { difficulty: 4, title: "HARD", subtitle: "High gravity | Hard questions", color: "#ff9e57", note: "Earth includes both medium and hard questions." },
    { difficulty: 5, title: "SUPER HARD", subtitle: "Strongest gravity | Super-hard questions", color: "var(--pink)" }
  ];

  return `
    <section class="screen planet-picker-screen">
      <h1 class="heading">CHOOSE YOUR PLANET</h1>
      <div class="planet-groups">
        ${groups.map((group) => planetGroupHtml(group)).join("")}
      </div>
    </section>
  `;
}

function planetGroupHtml(group) {
  const planets = state.planets.filter((planet) => planet.difficulty === group.difficulty);
  return `
    <section class="card planet-group">
      <h2 class="group-title" style="color:${group.color}">${group.title}</h2>
      <p class="subheading">${group.subtitle}</p>
      ${group.note ? `<p class="small-note">${group.note}</p>` : ""}
      <div class="planet-grid">
        ${planets.map((planet) => `
          <button class="planet-pick" data-action="selectPlanet" data-id="${planet.id}">
            ${planetHtml(planet, 82)}
            <p class="planet-name">${planet.name}</p>
            <p class="planet-gravity">${planet.gravity.toFixed(2)} m/s&sup2;</p>
          </button>
        `).join("")}
      </div>
    </section>
  `;
}

function selectedScreen() {
  const planet = state.selectedPlanet;
  return `
    <section class="screen">
      <h1 class="heading">YOU CHOSE</h1>
      ${planetHtml(planet, 190, true)}
      <h2 class="heading">${planet.name.toUpperCase()}</h2>
    </section>
  `;
}

function gravityScreen() {
  const planet = state.selectedPlanet;
  return `
    <section class="screen" style="background:linear-gradient(180deg,#${planet.colors[0]}66,#${planet.colors[1]}66);border-radius:8px">
      ${planetHtml(planet, 150)}
      <h1 class="heading">${planet.name.toUpperCase()}</h1>
      <div class="card">
        <p class="subheading">GRAVITY</p>
        <p class="big-number">${planet.gravity.toFixed(2)} m/s&sup2;</p>
        <p class="subheading">${escapeHtml(planet.gravityDescription)}</p>
      </div>
      <button class="primary" data-action="beginPlanet">LAND ON ${planet.name.toUpperCase()}</button>
    </section>
  `;
}

function astronautScreen(message, movement) {
  return `
    <section class="screen">
      <h1 class="heading">${message}</h1>
      <p class="subheading">STREAK: ${state.streak}</p>
      <div class="astronaut-stage">
        <div class="planet-base">
          ${planetHtml(state.selectedPlanet, 270)}
        </div>
        <div class="platform-stack" aria-label="${state.streak} platforms">
          ${platformsHtml(state.streak)}
        </div>
        <div class="astronaut-wrap">
          <div class="astronaut-mover ${movement}">
          <img class="astronaut" src="assets/images/astronaut.png" alt="Astronaut">
          </div>
        </div>
      </div>
    </section>
  `;
}

function platformsHtml(count) {
  if (count === 0) {
    return `<div class="platform empty">LANDING ZONE</div>`;
  }

  return Array.from({ length: Math.min(count, 8) }, (_, index) => {
    const label = count - index;
    return `<div class="platform">#${label}</div>`;
  }).join("");
}

function questionScreen() {
  const question = state.currentQuestion;
  return `
    <section class="screen">
      <div class="hud">
        <span>QUESTION ${state.usedQuestionIds.size} / ${eligibleQuestions().length}</span>
        <span id="timer">${timeText(currentElapsedTime())}</span>
      </div>
      <button class="card question-card" data-action="showAnswer">
        ${escapeHtml(question.prompt)}
        ${question.hint ? `<p class="small-note">Hint: ${escapeHtml(question.hint)}</p>` : ""}
      </button>
      <p class="subheading">Tap the question when you are ready to answer</p>
    </section>
  `;
}

function answerScreen() {
  const question = state.currentQuestion;
  if (question.answerStyle === "multipleChoice" && question.choices) {
    return `
      <section class="screen">
        <h1 class="heading">Choose the answer</h1>
        <div class="answer-list">
          ${question.choices.map((choice) => `
            <button class="choice" data-action="submitChoice" data-choice="${escapeHtml(choice)}">${escapeHtml(choice)}</button>
          `).join("")}
        </div>
      </section>
    `;
  }

  return `
    <section class="screen">
      <h1 class="heading">Type your answer</h1>
      <div class="card name-box">
        <label class="label" for="answer">ANSWER</label>
        <input class="text-input" id="answer" value="${escapeHtml(state.typedAnswer)}" autofocus>
      </div>
      <button class="primary" data-action="submitTyped">SUBMIT</button>
    </section>
  `;
}

function incorrectScreen() {
  return messageScreen("Not quite", `Answer: ${state.currentQuestion.answers[0]}`);
}

function finishScreen() {
  return `
    <section class="screen">
      <h1 class="heading">MISSION FINISHED</h1>
      <div class="card">
        <p class="big-number">${state.streak}</p>
        <p class="subheading">correct answers in ${timeText(state.finalTime)}</p>
      </div>
    </section>
  `;
}

function leaderboardScreen() {
  const rows = selectedPlanetScores();
  return `
    <section class="screen">
      <h1 class="heading">${state.selectedPlanet.name.toUpperCase()} LEADERBOARD</h1>
      <table class="leaderboard card">
        <thead>
          <tr><th>#</th><th>Name</th><th>Streak</th><th>Time</th></tr>
        </thead>
        <tbody>
          ${rows.length ? rows.map((score, index) => `
            <tr>
              <td>${index + 1}</td>
              <td>${escapeHtml(score.playerName)}</td>
              <td>${score.streak}</td>
              <td>${timeText(score.duration || 0)}</td>
            </tr>
          `).join("") : `<tr><td colspan="4">No scores yet.</td></tr>`}
        </tbody>
      </table>
      <div class="button-row">
        <button class="primary" data-action="tryAgain">TRY AGAIN</button>
        <button class="plain" data-action="goHome">HOME</button>
      </div>
    </section>
  `;
}

function messageScreen(title, text = "") {
  return `
    <section class="screen">
      <h1 class="heading">${escapeHtml(title)}</h1>
      ${text ? `<p class="subheading">${escapeHtml(text)}</p>` : ""}
    </section>
  `;
}

function planetHtml(planet, size, selected = false) {
  return `
    <div class="planet ${selected ? "selected" : ""}" style="--size:${size}px;--c1:#${planet.colors[0]};--c2:#${planet.colors[1]}" aria-label="${escapeHtml(planet.name)}"></div>
  `;
}

function wireEvents() {
  const nameInput = document.querySelector("#playerName");
  if (nameInput) {
    nameInput.focus();
    nameInput.addEventListener("input", () => state.playerName = nameInput.value);
    nameInput.addEventListener("keydown", (event) => {
      if (event.key === "Enter") play();
    });
  }

  const answerInput = document.querySelector("#answer");
  if (answerInput) {
    answerInput.focus();
    answerInput.addEventListener("input", () => state.typedAnswer = answerInput.value);
    answerInput.addEventListener("keydown", (event) => {
      if (event.key === "Enter") submitAnswer(answerInput.value);
    });
  }

  document.querySelectorAll("[data-action]").forEach((element) => {
    element.addEventListener("click", () => handleAction(element));
  });

  if (state.screen === "question") {
    startQuestionTimer();
  }
}

function handleAction(element) {
  const action = element.dataset.action;
  if (action === "play") play();
  if (action === "selectPlanet") selectPlanet(element.dataset.id);
  if (action === "beginPlanet") beginPlanet();
  if (action === "showAnswer") setScreen("answer");
  if (action === "submitChoice") submitAnswer(element.dataset.choice);
  if (action === "submitTyped") submitAnswer(document.querySelector("#answer").value);
  if (action === "tryAgain") beginPlanet();
  if (action === "goHome") goHome();
}

function play() {
  setScreen("choosePlanet");
}

function selectPlanet(id) {
  state.selectedPlanet = state.planets.find((planet) => planet.id === id);
  setScreen("selected");
  later(delays.selectedToGravity, () => setScreen("gravity"));
}

function beginPlanet() {
  state.streak = 0;
  state.usedQuestionIds = new Set();
  state.startedAt = null;
  state.finalTime = 0;
  setScreen("astronaut");
  later(delays.readyToQuestion, prepareQuestion);
}

function prepareQuestion() {
  if (!state.startedAt) state.startedAt = Date.now();
  const pool = eligibleQuestions().filter((question) => !state.usedQuestionIds.has(question.id));

  if (pool.length === 0) {
    stopTimer();
    setScreen("winner");
    later(delays.winner, completeGame);
    return;
  }

  state.currentQuestion = pool[Math.floor(Math.random() * pool.length)];
  state.usedQuestionIds.add(state.currentQuestion.id);
  state.typedAnswer = "";
  setScreen("question");
}

function submitAnswer(answer) {
  const correct = state.currentQuestion.answers.some((accepted) => answersMatch(answer, accepted));
  const completedAllQuestions = correct && state.usedQuestionIds.size === eligibleQuestions().length;

  if (!correct || completedAllQuestions) stopTimer();
  setScreen("loading");

  later(delays.checkingAnswer, () => {
    setScreen(correct ? "correct" : "incorrect");
    later(correct ? delays.correctResult : delays.incorrectResult, () => showMovement(correct, completedAllQuestions));
  });
}

function showMovement(correct, completedAllQuestions) {
  if (correct) {
    state.streak += 1;
  }

  setScreen(correct ? "movementUp" : "movementDown");

  if (correct) {
    later(delays.movement, () => completedAllQuestions ? winGame() : prepareQuestion());
  } else {
    later(delays.movement, completeGame);
  }
}

function winGame() {
  stopTimer();
  setScreen("winner");
  later(delays.winner, completeGame);
}

function completeGame() {
  stopTimer();

  if (state.streak > 0) {
    state.scores.push({
      id: crypto.randomUUID ? crypto.randomUUID() : String(Date.now()),
      playerName: displayName(),
      planetID: state.selectedPlanet.id,
      planetName: state.selectedPlanet.name,
      streak: state.streak,
      duration: state.finalTime,
      date: new Date().toISOString()
    });
    saveScores();
  }

  setScreen("finish");
  later(delays.finish, () => setScreen("leaderboard"));
}

function goHome() {
  state.selectedPlanet = null;
  state.currentQuestion = null;
  state.streak = 0;
  state.startedAt = null;
  state.finalTime = 0;
  setScreen("home");
}

function setScreen(screen) {
  if (questionTimer && screen !== "question") {
    window.clearInterval(questionTimer);
    questionTimer = null;
  }

  state.screen = screen;
  render();
}

function startQuestionTimer() {
  if (questionTimer) return;

  questionTimer = window.setInterval(() => {
    if (state.screen !== "question") {
      window.clearInterval(questionTimer);
      questionTimer = null;
      return;
    }

    const timer = document.querySelector("#timer");
    if (timer) {
      timer.textContent = timeText(currentElapsedTime());
    }
  }, 100);
}

function later(milliseconds, action) {
  window.setTimeout(action, milliseconds);
}

function eligibleQuestions() {
  const difficulty = state.selectedPlanet.id === "earth"
    ? new Set([3, 4])
    : new Set([state.selectedPlanet.difficulty]);
  return state.questions.filter((question) => difficulty.has(question.difficulty));
}

function displayName() {
  const name = state.playerName.trim();
  return name || "Space Explorer";
}

function stopTimer() {
  if (state.finalTime === 0) {
    state.finalTime = currentElapsedTime();
  }
}

function currentElapsedTime() {
  if (state.finalTime > 0) return state.finalTime;
  if (!state.startedAt) return 0;
  return (Date.now() - state.startedAt) / 1000;
}

function selectedPlanetScores() {
  return state.scores
    .filter((score) => score.planetID === state.selectedPlanet.id)
    .sort((left, right) => {
      if (left.streak !== right.streak) return right.streak - left.streak;
      if ((left.duration || Infinity) !== (right.duration || Infinity)) {
        return (left.duration || Infinity) - (right.duration || Infinity);
      }
      return new Date(left.date) - new Date(right.date);
    })
    .slice(0, 10);
}

function answersMatch(answer, accepted) {
  const left = normalise(answer);
  const right = normalise(accepted);
  if (!left || !right) return false;
  if (left === right) return true;
  if (left.length >= 4 && right.length >= 4 && (left.includes(right) || right.includes(left))) return true;
  return levenshtein(left, right) <= (right.length <= 5 ? 1 : 2);
}

function normalise(text) {
  return String(text).toLowerCase().replace(/[^a-z0-9 ]/g, "").replace(/\s+/g, " ").trim();
}

function levenshtein(left, right) {
  const costs = Array.from({ length: right.length + 1 }, (_, index) => index);
  for (let i = 1; i <= left.length; i += 1) {
    let previous = i;
    for (let j = 1; j <= right.length; j += 1) {
      const old = costs[j];
      costs[j] = left[i - 1] === right[j - 1]
        ? costs[j - 1]
        : Math.min(costs[j - 1], previous, costs[j]) + 1;
      previous = old;
    }
    costs[0] = i;
  }
  return costs[right.length];
}

function timeText(seconds) {
  const tenths = Math.max(0, Math.round(seconds * 10));
  const minutes = Math.floor(tenths / 600);
  const wholeSeconds = Math.floor((tenths % 600) / 10);
  const fraction = tenths % 10;
  return `${minutes}:${String(wholeSeconds).padStart(2, "0")}.${fraction}`;
}

function loadScores() {
  try {
    return JSON.parse(localStorage.getItem("leapOfSpace.scores") || "[]");
  } catch {
    return [];
  }
}

function saveScores() {
  localStorage.setItem("leapOfSpace.scores", JSON.stringify(state.scores));
}

function escapeHtml(value) {
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;")
    .replaceAll("'", "&#039;");
}
