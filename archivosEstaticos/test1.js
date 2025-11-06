const express = require('express');
const bodyParser = require('body-parser');
const app = express();
const db = require('sqlite3'); // Simulamos una base de datos

app.use(bodyParser.urlencoded({ extended: true }));
app.use(express.static('public')); // Permite archivos estáticos

// --- VULNERABILIDAD 1: SQL INJECTION (Simulación) ---
// El nombre de usuario se concatena directamente en la consulta.
app.get('/user', (req, res) => {
    const userId = req.query.id; // Datos del usuario vienen de la URL

    // Consulta altamente vulnerable. Un atacante puede cerrar las comillas e inyectar comandos.
    const sql = "SELECT * FROM users WHERE id = '" + userId + "' AND activo = 1";
    
    // Ejecución de la consulta (simulada)
    db.run(sql, (err, row) => {
        if (err) {
            // Manejo de errores inseguro, expone detalles del error.
            return res.status(500).send("Error de DB: " + err.message);
        }
        res.send(row);
    });
});

// --- VULNERABILIDAD 2: CROSS-SITE SCRIPTING (XSS) ---
// El parámetro 'mensaje' se imprime sin escapar en la respuesta HTML.
app.get('/search', (req, res) => {
    const searchQuery = req.query.mensaje; // Entrada del usuario

    // Se imprime la entrada del usuario directamente en el DOM.
    // Un atacante puede enviar un payload como: <script>alert('XSS')</script>
    const htmlResponse = `
        <html>
            <body>
                <h1>Resultado de búsqueda para:</h1>
                <p>Mostrando resultados para: ${searchQuery}</p> 
            </body>
        </html>
    `;
    res.send(htmlResponse);
});

// --- VULNERABILIDAD 3: CROSS-SITE REQUEST FORGERY (CSRF) ---
// Formulario de cambio de contraseña sin token anti-CSRF.
app.post('/change-password', (req, res) => {
    // No hay verificación de token CSRF.
    const newPass = req.body.new_password; 
    const username = req.body.username; 
    
    // Lógica para cambiar la contraseña (función crítica).
    console.log(`Cambiando contraseña de ${username} a ${newPass}`);

    // El servidor asume que la solicitud viene de un usuario legítimo.
    // La prueba CSRF debe detectar la ausencia de un campo oculto con un token.
    res.send('Contraseña actualizada (CSRF no mitigado)');
});

app.listen(3000, () => {
    console.log('Servidor inseguro corriendo en puerto 3000');
});