import CONFIG from '../config';

// --------------------------------------------------------------------------------------------------------//
// Primary color constants for the theme
export const PRIMARY_MAIN = "#444E56"; // The main primary color used for buttons, highlights, etc.
export const primary_50 = "#004D77"; // The 50 variant of the primary color

// Background color constants
export const SECONDARY_MAIN = "#D3D3D3"; // The main secondary color used for less prominent elements

// Chat component background colors
export const CHAT_BODY_BACKGROUND = "#FFFFFF"; // Background color for the chat body area
export const CHAT_LEFT_PANEL_BACKGROUND = "#004D77"; // Background color for the left panel in the chat
export const ABOUT_US_HEADER_BACKGROUND = "#FFFFFF"; // Background color for the About Us section in the left panel
export const FAQ_HEADER_BACKGROUND = "#FFFFFF"; // Background color for the FAQ section in the left panel
export const ABOUT_US_TEXT = "#FFFFFF"; // Text color for the About Us section in the left panel
export const FAQ_TEXT = "#FFFFFF"; // Text color for the FAQ section in the left panel
export const HEADER_BACKGROUND = "#FFFFFF"; // Background color for the header
export const HEADER_TEXT_GRADIENT = "#004D77"; // Text gradient color for the header

// Message background colors
export const BOTMESSAGE_BACKGROUND = "#C0EAE3"; // Background color for messages sent by the bot
export const USERMESSAGE_BACKGROUND = "lightblue"; // Background color for messages sent by the user

// --------------------------------------------------------------------------------------------------------//
// --------------------------------------------------------------------------------------------------------//

// Text Constants
export const TEXT = {
  EN: {
    APP_NAME: "Chatbot Template App",
    APP_ASSISTANT_NAME: "GenAI Bot",
    ABOUT_US_TITLE: "About us",
    ABOUT_US: "Welcome to AI Career Assistant! We're here to help you advance your career with personalized guidance from specialized AI personas.",
    FAQ_TITLE: "Frequently Asked Questions",
    FAQS: [
      "How do I transition to a DevOps career?",
      "What are essential DevOps tools I should learn?",
      "How do I prepare for a DevOps engineer interview?",
      "What's the difference between CI and CD?",
      "How do I get started with Kubernetes?",
      "What cloud certifications should I pursue?",
      "How do I build a DevOps portfolio?",
      "What salary can I expect as a DevOps engineer?"
    ],
    CHAT_HEADER_TITLE: "DRTx Knowledge Bot",
    CHAT_INPUT_PLACEHOLDER: "Ask about your career goals, interviews, resume, or industry insights...",
    HELPER_TEXT: "Cannot send empty message",
    SPEECH_RECOGNITION_START: "Start Listening",
    SPEECH_RECOGNITION_STOP: "Stop Listening",
    SPEECH_RECOGNITION_HELPER_TEXT: "Stop speaking to send the message",
    THINKING: "Thinking...",
    NO_RESPONSE: "No response received",
    ERROR_MESSAGE: "Sorry, I encountered an error. Please try again later."
  },
  ES: {
    APP_NAME: "Aplicación de Plantilla de Chatbot",
    APP_ASSISTANT_NAME: "Bot GenAI",
    ABOUT_US_TITLE: "Acerca de nosotros",
    ABOUT_US: "¡Bienvenido al Asistente de Carrera AI! Estamos aquí para ayudarte a avanzar en tu carrera con orientación personalizada de personas AI especializadas.",
    FAQ_TITLE: "Preguntas frecuentes",
    FAQS: [
      "¿Cómo puedo hacer la transición a una carrera de DevOps?",
      "¿Cuáles son las herramientas esenciales de DevOps que debo aprender?",
      "¿Cómo me preparo para una entrevista de ingeniero DevOps?",
      "¿Cuál es la diferencia entre CI y CD?",
      "¿Cómo empiezo con Kubernetes?",
      "¿Qué certificaciones de nube debo buscar?",
      "¿Cómo construyo un portafolio de DevOps?",
      "¿Qué salario puedo esperar como ingeniero DevOps?"
    ],
    CHAT_HEADER_TITLE: "Bot de conocimiento DRTx",
    CHAT_INPUT_PLACEHOLDER: "Pregunta sobre tus objetivos profesionales, entrevistas, currículum o perspectivas de la industria...",
    HELPER_TEXT: "No se puede enviar un mensaje vacío",
    SPEECH_RECOGNITION_START: "Comenzar a Escuchar",
    SPEECH_RECOGNITION_STOP: "Dejar de Escuchar",
    SPEECH_RECOGNITION_HELPER_TEXT: "Deja de hablar para enviar el mensaje",
    THINKING: "Pensando...",
    NO_RESPONSE: "No se recibió respuesta",
    ERROR_MESSAGE: "Lo siento, encontré un error. Por favor, inténtalo de nuevo más tarde."
  }
};

export const SWITCH_TEXT = {
  SWITCH_LANGUAGE_ENGLISH: "English",
  SWITCH_TOOLTIP_ENGLISH: "Language",
  SWITCH_LANGUAGE_SPANISH: "Español",
  SWITCH_TOOLTIP_SPANISH: "Idioma"
};

export const LANDING_PAGE_TEXT = {
  EN: {
    CHOOSE_LANGUAGE: "Choose language:",
    ENGLISH: "English",
    SPANISH: "Español",
    SAVE_CONTINUE: "Save and Continue",
    APP_ASSISTANT_NAME: "DRTx Knowledge Bot Landing Page",
  },
  ES: {
    CHOOSE_LANGUAGE: "Elige el idioma:",
    ENGLISH: "English",
    SPANISH: "Español",
    SAVE_CONTINUE: "Guardar y continuar",
    APP_ASSISTANT_NAME: "Página de inicio del bot de conocimiento de DRTx",
  }
};

export const DISABILITY_RIGHTS_VISION = {
  EN: "tell about disability rights vision",
  ES: "tell about disability rights vision in Spanish"
};


// --------------------------------------------------------------------------------------------------------//
// --------------------------------------------------------------------------------------------------------//

// API endpoints


export const CHAT_API = process.env.REACT_APP_CHAT_API; // URL for the chat API endpoint
export const WEBSOCKET_API = process.env.REACT_APP_WEBSOCKET_API; // URL for the WebSocket API endpoint
export const AMAZON_Q_API = CONFIG.api.endpoint; // Amazon Q Business API endpoint

// --------------------------------------------------------------------------------------------------------//
// --------------------------------------------------------------------------------------------------------//

// Features
export const ALLOW_FILE_UPLOAD = false; // Set to true to enable file upload feature
export const ALLOW_VOICE_RECOGNITION = true; // Set to true to enable voice recognition feature
export const ALLOW_FEEDBACK = false; // Set to false to disable upvote/downvote feedback feature

export const ALLOW_MULTLINGUAL_TOGGLE = true; // Set to true to enable multilingual support
export const ALLOW_LANDING_PAGE = true; // Set to true to enable the landing page

// Bot response timing (in milliseconds) - set to 0 to disable
export const BOT_RESPONSE_DELAY = 1000; // Delay before showing bot's response
export const BOT_TYPING_SPEED = 50; // Milliseconds per character for typing effect (lower = faster, 0 = disabled)

// --------------------------------------------------------------------------------------------------------//
// Styling under work, would reccomend keeping it false for now
export const ALLOW_MARKDOWN_BOT = false; // Set to true to enable markdown support for bot messages
export const ALLOW_FAQ = true; // Set to true to enable the FAQs to be visible in Chat body 