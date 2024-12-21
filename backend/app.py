from flask import Flask, request, jsonify
import pandas as pd
import random

app = Flask(__name__)

# Charger le dictionnaire de mots
dictionary = pd.read_csv("./data/dictionary.csv", encoding='ISO-8859-1')

# Variables globales pour le jeu
current_word = ""
masked_word = ""
attempts_left = 0

# Fonction pour masquer le mot à deviner
def word_to_guess(word):
    return ''.join(['_' if char not in [' ', '-', "'"] else char for char in word])

# Fonction pour remplacer les lettres trouvées
def replace_letter(letter, random_word, current_word):
    return ''.join(
        [letter if random_word[i] == letter else (random_word[i] if random_word[i] in [' ', '-', "'"] else current_word[i]) for i in range(len(random_word))]
    )

# Endpoint : Démarrer une nouvelle partie
@app.route('/start', methods=['GET'])
def start_game():
    global current_word, masked_word, attempts_left

    # Choisir un mot aléatoire
    level = request.args.get('level', 'EASY').upper()
    words = dictionary[dictionary['level'] == level]['words'].tolist()

    if not words:
        return jsonify({"error": f"No words available for level {level}"}), 400

    current_word = random.choice(words).upper()
    masked_word = word_to_guess(current_word)
    attempts_left = 8

    return jsonify({
        "word_state": masked_word,
        "attempts_left": attempts_left
    })

# Endpoint : Envoyer une lettre
@app.route('/guess', methods=['POST'])
def guess_letter():
    global current_word, masked_word, attempts_left

    data = request.json
    letter = data.get('letter', '').upper()

    if not letter or len(letter) != 1 or not letter.isalpha():
        return jsonify({"error": "Invalid input. Please send a single letter."}), 400

    if letter in current_word:
        masked_word = replace_letter(letter, current_word, masked_word)
        if masked_word == current_word:
            return jsonify({
                "word_state": masked_word,
                "attempts_left": attempts_left,
                "status": "win"
            })
    else:
        attempts_left -= 1

    status = "lose" if attempts_left == 0 else "ongoing"

    return jsonify({
        "word_state": masked_word,
        "attempts_left": attempts_left,
        "status": status
    })

if __name__ == '__main__':
    app.run(debug=True)
