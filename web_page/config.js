// config.js - Para diferentes entornos
const CONFIG = {
    development: {
        apiUrl: 'https://tu-api-dev.execute-api.region.amazonaws.com/dev',
        timeout: 5000
    },
    production: {
        apiUrl: 'https://tu-api-prod.execute-api.region.amazonaws.com/prod',
        timeout: 10000
    }
};

// Detectar entorno
const ENV = window.location.hostname === 'localhost' ? 'development' : 'production';
const API_URL = CONFIG[ENV].apiUrl;

export { API_URL };