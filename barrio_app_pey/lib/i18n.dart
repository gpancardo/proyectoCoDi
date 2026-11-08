/// Textos y opciones compartidas de la interfaz en español de México.
abstract final class I18n {
  static const appName = 'Barrio';
  static const welcome = 'Encuentra algo rico cerca';
  static const onboardingTitle = 'Lo bueno empieza cerca';
  static const onboardingSubtitle = 'Así buscamos opciones cerca de tu zona.';
  static const nameLabel = '¿Cómo te llamas?';
  static const phoneLabel = 'Tu celular';
  static const zoneLabel = 'Alcaldía';
  static const neighborhoodLabel = 'Colonia';
  static const addressHint = 'Ej. Del Valle';
  static const continueLabel = 'Continuar';
  static const chatGreeting = '¡Hola! ¿Qué se te antoja hoy?';
  static const chatHint = 'Escribe lo que buscas cerca de ti';
  static const voiceNotReady = 'Pronto podrás dictar tu búsqueda.';
  static const connectionHint = 'Estoy preparando opciones de tu zona.';

  static const giros = [
    'Abarrotes',
    'Antojitos',
    'Belleza',
    'Café',
    'Comida',
    'Farmacia',
    'Ferretería',
    'Florería',
    'Frutería',
    'Lavandería',
    'Panadería',
    'Papelería',
    'Taller',
    'Otro',
  ];

  // Mismos nombres que ZONAS en backend/src/text.js.
  static const alcaldiasCdmx = [
    'Álvaro Obregón',
    'Azcapotzalco',
    'Benito Juárez',
    'Coyoacán',
    'Cuajimalpa',
    'Cuauhtémoc',
    'Gustavo A. Madero',
    'Iztacalco',
    'Iztapalapa',
    'Magdalena Contreras',
    'Miguel Hidalgo',
    'Milpa Alta',
    'Tláhuac',
    'Tlalpan',
    'Venustiano Carranza',
    'Xochimilco',
  ];
}
