# Scrabble Word Checker

A [Lamdera](https://lamdera.com) web app: type a word, press **Enter**, and it tells
you whether the word is a valid Scrabble word (using the TWL06 tournament word list)
and shows a dictionary definition.

## How it works

- **Frontend** (`src/Frontend.elm`) — a single text input. On submit it sends the
  word to the backend over Lamdera's typed wire.
- **Backend** (`src/Backend.elm`) — checks the word against the TWL06 word list and
  fetches a definition from the free [dictionaryapi.dev](https://dictionaryapi.dev)
  API (no API key required), then sends the combined result back to the frontend.
- **Word list** (`src/Words.elm`) — the full
  [TWL06](https://github.com/kamilmielnik/scrabble-dictionaries/blob/master/english/twl06.txt)
  dictionary (~178k words) embedded as a string. `src/Dictionary.elm` parses it once
  into a `Set` for fast lookups. Because it lives in a top-level constant rather than
  in the persisted `BackendModel`, it's built lazily once and never bloats state.

## Running locally

Install the [Lamdera CLI](https://dashboard.lamdera.app/docs/download), then:

```sh
lamdera live
```

and open <http://localhost:8000>.

## Deploying

```sh
lamdera deploy
```

## Notes

- Scrabble validity is determined **only** by the TWL06 list. A word can have a
  dictionary definition while still not being a legal Scrabble play, and vice versa —
  both pieces of information are shown independently.
