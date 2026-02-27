// Configuración de la API
const API_CONFIG = {
    // Cambia esta URL por la URL de tu API Gateway
    baseURL: 'https://tu-api-gateway-url.execute-api.region.amazonaws.com/pro',
    endpoints: {
        saveData: '/data'
    }
};

// Función para mostrar mensajes
function showMessage(message, type) {
    const messageDiv = document.getElementById('message');
    messageDiv.textContent = message;
    messageDiv.className = `message ${type}`;
}

// Función para validar el formulario
function validateForm(data) {
    if (!data.key || data.key.trim() === '') {
        return 'La clave es requerida';
    }
    if (!data.value || data.value.trim() === '') {
        return 'El valor es requerido';
    }
    return null;
}

// Función para enviar datos a la API
async function sendToAPI(formData) {
    try {
        const response = await fetch(`${API_CONFIG.baseURL}${API_CONFIG.endpoints.saveData}`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                // Si tu API requiere autenticación, añade aquí los headers necesarios
                // 'Authorization': 'Bearer tu-token'
            },
            body: JSON.stringify(formData)
        });

        const data = await response.json();

        if (!response.ok) {
            throw new Error(data.message || 'Error en la petición');
        }

        return { success: true, data };
    } catch (error) {
        return { success: false, error: error.message };
    }
}

// Función para obtener datos de ejemplo (opcional)
async function fetchData() {
    try {
        const response = await fetch(`${API_CONFIG.baseURL}${API_CONFIG.endpoints.saveData}`);
        const data = await response.json();
        return data;
    } catch (error) {
        console.error('Error fetching data:', error);
        return null;
    }
}

// Manejar el envío del formulario
document.getElementById('dataForm').addEventListener('submit', async (e) => {
    e.preventDefault();
    
    const submitBtn = document.getElementById('submitBtn');
    const formData = {
        key: document.getElementById('key').value,
        value: document.getElementById('value').value,
        category: document.getElementById('category').value,
        description: document.getElementById('description').value,
        timestamp: new Date().toISOString()
    };

    // Validar formulario
    const validationError = validateForm(formData);
    if (validationError) {
        showMessage(validationError, 'error');
        return;
    }

    // Deshabilitar botón durante el envío
    submitBtn.disabled = true;
    showMessage('Enviando datos...', 'info');

    // Enviar a la API
    const result = await sendToAPI(formData);

    if (result.success) {
        showMessage('¡Datos guardados exitosamente!', 'success');
        document.getElementById('dataForm').reset();
    } else {
        showMessage(`Error: ${result.error}`, 'error');
    }

    // Habilitar botón nuevamente
    submitBtn.disabled = false;
});

// Opcional: Cargar datos existentes al iniciar la página
async function loadInitialData() {
    try {
        const data = await fetchData();
        if (data) {
            console.log('Datos cargados:', data);
            // Aquí puedes mostrar los datos en la interfaz si lo deseas
        }
    } catch (error) {
        console.error('Error cargando datos iniciales:', error);
    }
}

// Inicializar la página
document.addEventListener('DOMContentLoaded', () => {
    console.log('Formulario inicializado');
    // loadInitialData(); // Descomentar si quieres cargar datos al inicio
});