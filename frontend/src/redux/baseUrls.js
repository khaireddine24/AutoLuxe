/**
Définitions des constantes globales pour l’URL de base de l’API et
la durée d’affichage des notifications. Ces valeurs sont importées
dans les autres modules pour éviter la duplication et simplifier
les changements de configuration.
*/

// CRA remplace les variables d'environnement `REACT_APP_*` au moment du build.
// En production, définissez `REACT_APP_API_BASE_URL` pour pointer vers l'API backend.
export const baseUrl = process.env.REACT_APP_API_BASE_URL || 'http://localhost:8000/' // URL de base de l’API Django/DRF
export const notificationTime = 3000 // Durée (ms) d’affichage des notifications