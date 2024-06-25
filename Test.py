import nltk
import pandas as pd
from nltk.corpus import wordnet as wn
import streamlit as st
from datetime import datetime
import matplotlib.pyplot as plt

# Télécharger les ressources nécessaires de NLTK
nltk.download('punkt')
nltk.download('wordnet')

# Créer une base de données simple pour les fonds
data = {
    'fund_name': ['Fund A', 'Fund B', 'Fund C'],
    'aum': [1000000, 2000000, 1500000],
    'quantity': [500, 1000, 750]
}
funds_df = pd.DataFrame(data)

class Chatbot:
    def __init__(self):
        self.scenarios = {
            "what time is it": self.get_current_time,
            "current time": self.get_current_time,
            "tell me a joke": self.tell_joke,
            "what is the date": self.get_current_date,
            "current date": self.get_current_date,
            "aum of": self.get_aum,
            "quantity of": self.get_quantity,
            "both of": self.get_both
        }
        self.qa_pairs = {
            "hello": "Hi there! How can I help you?",
            "how are you": "I'm just a chatbot, but I'm doing great! How about you?",
            "what is your name": "I'm a Streamlit chatbot. Nice to meet you!",
            "bye": "Goodbye! Have a great day!"
        }

    def find_response(self, user_input):
        user_input_tokens = nltk.word_tokenize(user_input.lower())
        
        # Vérifier les similitudes avec les scénarios
        for scenario, action in self.scenarios.items():
            scenario_tokens = nltk.word_tokenize(scenario.lower())
            similarity = self.compute_similarity(user_input_tokens, scenario_tokens)
            if similarity > 0.7:  # Seuil de similarité pour les scénarios
                return action(user_input)

        # Sinon, utiliser la similarité pour trouver la meilleure réponse parmi les questions-réponses
        max_similarity = 0
        best_response = "I don't understand that."

        for question, answer in self.qa_pairs.items():
            question_tokens = nltk.word_tokenize(question.lower())
            similarity = self.compute_similarity(user_input_tokens, question_tokens)
            if similarity > max_similarity:
                max_similarity = similarity
                best_response = answer

        return best_response

    def get_current_time(self, user_input):
        now = datetime.now()
        return f"The current time is {now.strftime('%H:%M:%S')}."

    def tell_joke(self, user_input):
        return "Why don't scientists trust atoms? Because they make up everything!"

    def get_current_date(self, user_input):
        today = datetime.today()
        return f"Today's date is {today.strftime('%Y-%m-%d')}."

    def get_aum(self, user_input):
        fund_name = self.extract_fund_name(user_input)
        if fund_name in funds_df['fund_name'].values:
            aum = funds_df[funds_df['fund_name'] == fund_name]['aum'].values[0]
            return f"The AUM of {fund_name} is {aum}."
        else:
            return "Fund not found."

    def get_quantity(self, user_input):
        fund_name = self.extract_fund_name(user_input)
        if fund_name in funds_df['fund_name'].values:
            quantity = funds_df[funds_df['fund_name'] == fund_name]['quantity'].values[0]
            return f"The quantity held of {fund_name} is {quantity}."
        else:
            return "Fund not found."

    def get_both(self, user_input):
        fund_name = self.extract_fund_name(user_input)
        if fund_name in funds_df['fund_name'].values:
            aum = funds_df[funds_df['fund_name'] == fund_name]['aum'].values[0]
            quantity = funds_df[funds_df['fund_name'] == fund_name]['quantity'].values[0]
            self.plot_aum_quantity(fund_name, aum, quantity)
            return f"The AUM of {fund_name} is {aum} and the quantity held is {quantity}."
        else:
            return "Fund not found."

    def plot_aum_quantity(self, fund_name, aum, quantity):
        fig, ax1 = plt.subplots()

        color = 'tab:blue'
        ax1.set_xlabel('Metric')
        ax1.set_ylabel('AUM', color=color)
        ax1.bar('AUM', aum, color=color)
        ax1.tick_params(axis='y', labelcolor=color)

        ax2 = ax1.twinx()  
        color = 'tab:red'
        ax2.set_ylabel('Quantity', color=color)  
        ax2.bar('Quantity', quantity, color=color)
        ax2.tick_params(axis='y', labelcolor=color)

        plt.title(f'AUM and Quantity for {fund_name}')
        fig.tight_layout()  
        st.pyplot(fig)

    def extract_fund_name(self, user_input):
        # Extraction simple du nom du fonds (à améliorer selon les besoins)
        tokens = nltk.word_tokenize(user_input)
        for fund_name in funds_df['fund_name'].values:
            if fund_name.lower() in [token.lower() for token in tokens]:
                return fund_name
        return None

    def compute_similarity(self, tokens1, tokens2):
        synsets1 = [wn.synsets(token)[0] for token in tokens1 if wn.synsets(token)]
        synsets2 = [wn.synsets(token)[0] for token in tokens2 if wn.synsets(token)]
        similarity = 0
        for syn1 in synsets1:
            for syn2 in synsets2:
                sim = syn1.path_similarity(syn2)
                if sim and sim > similarity:
                    similarity = sim
        return similarity

# Interface utilisateur avec Streamlit
st.title('Chatbot avec Streamlit')
st.write('Posez une question au chatbot.')

# Créer une instance du chatbot
chatbot = Chatbot()

# Entrée utilisateur
if user_input := st.chat_input("Vous:"):
    with st.chat_message("user"):
        st.write(user_input)
    
    response = chatbot.find_response(user_input)
    
    with st.chat_message("assistant"):
        st.write(response)
