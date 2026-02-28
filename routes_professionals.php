<?php

// ================================================================
//  PROFESSIONALS — Routes complètes Laravel
//  Fichier : routes/api.php  +  routes/web.php  (fusionnés ici)
//  Stack   : Laravel 11 · Sanctum (auth API) · React SPA
// ================================================================
// Structure :
//   SECTION A — routes/web.php   (SPA entry + Auth Sanctum)
//   SECTION B — routes/api.php   (toutes les routes API JSON)
//     1.  Auth & Profil utilisateur
//     2.  Référentiels (pays, villes, secteurs, compétences)
//     3.  Recherche & Suggestions
//     4.  Entreprises (public)
//     5.  Entreprises (espace entreprise - privé)
//     6.  Offres d'emploi / stages (public)
//     7.  Offres d'emploi / stages (espace entreprise)
//     8.  Candidatures (étudiant)
//     9.  Candidatures (entreprise/RH)
//     10. Avis & Notations
//     11. Messagerie / Chat
//     12. Notifications
//     13. Favoris / Bookmarks
//     14. Analytics
//     15. Administration
// ================================================================

use Illuminate\Support\Facades\Route;

use App\Http\Controllers\Auth\{
    RegisterController,
    LoginController,
    LogoutController,
    EmailVerificationController,
    PasswordResetController,
    SocialAuthController,
};

use App\Http\Controllers\User\{
    ProfileController,
    StudentProfileController,
    DashboardController,
};

use App\Http\Controllers\Reference\{
    CountryController,
    CityController,
    SectorController,
    SkillController,
};

use App\Http\Controllers\Search\{
    SearchController,
    SuggestionController,
    AutocompleteController,
};

use App\Http\Controllers\Company\{
    CompanyPublicController,
    CompanyController,
    CompanyMediaController,
    CompanyPublicationController,
    CompanyOrgController,
    CompanyHrContactController,
};

use App\Http\Controllers\JobOffer\{
    JobOfferPublicController,
    JobOfferController,
};

use App\Http\Controllers\Application\{
    StudentApplicationController,
    CompanyApplicationController,
};

use App\Http\Controllers\Review\{
    ReviewController,
    ReviewVoteController,
};

use App\Http\Controllers\Chat\{
    ConversationController,
    MessageController,
};

use App\Http\Controllers\NotificationController;
use App\Http\Controllers\BookmarkController;
use App\Http\Controllers\AnalyticsController;

use App\Http\Controllers\Admin\{
    AdminUserController,
    AdminCompanyController,
    AdminJobOfferController,
    AdminReviewController,
    AdminReportController,
    AdminSectorController,
    AdminDashboardController,
    AdminSuggestionController,
};

// ================================================================
//  SECTION A — routes/web.php
//  Tout le front-end React est servi par une seule route "catch-all"
//  Laravel Sanctum gère les cookies de session pour la SPA
// ================================================================

// Point d'entrée SPA React (doit rester en dernier dans web.php)
Route::get('/{any}', fn() => view('app'))->where('any', '.*')->name('spa');

// Sanctum CSRF cookie (obligatoire avant tout appel Sanctum depuis SPA)
// Déjà fourni par le package : GET /sanctum/csrf-cookie


// ================================================================
//  SECTION B — routes/api.php
//  Préfixe global : /api  (configuré dans bootstrap/app.php)
//  Middleware     : api, throttle:api
// ================================================================

// ----------------------------------------------------------------
//  1. AUTH & PROFIL UTILISATEUR
// ----------------------------------------------------------------

// Inscription
Route::post('/auth/register',                   [RegisterController::class, 'register'])
     ->name('auth.register');

// Connexion
Route::post('/auth/login',                      [LoginController::class, 'login'])
     ->name('auth.login');

// Connexion sociale (Google, LinkedIn)
Route::get('/auth/social/{provider}',           [SocialAuthController::class, 'redirect'])
     ->name('auth.social.redirect');
Route::get('/auth/social/{provider}/callback',  [SocialAuthController::class, 'callback'])
     ->name('auth.social.callback');

// Mot de passe oublié
Route::post('/auth/forgot-password',            [PasswordResetController::class, 'sendLink'])
     ->name('auth.forgot-password');
Route::post('/auth/reset-password',             [PasswordResetController::class, 'reset'])
     ->name('auth.reset-password');

// Routes authentifiées (Sanctum)
Route::middleware('auth:sanctum')->group(function () {

    // Déconnexion
    Route::post('/auth/logout',                 [LogoutController::class, 'logout'])
         ->name('auth.logout');

    // Vérification email
    Route::get('/auth/email/verify/{id}/{hash}', [EmailVerificationController::class, 'verify'])
         ->middleware('signed')
         ->name('verification.verify');
    Route::post('/auth/email/resend',            [EmailVerificationController::class, 'resend'])
         ->name('verification.send');

    // --- Profil utilisateur connecté ---
    Route::prefix('me')->name('me.')->group(function () {

        Route::get('/',                         [ProfileController::class, 'show'])
             ->name('show');                    // GET  /api/me

        Route::put('/',                         [ProfileController::class, 'update'])
             ->name('update');                  // PUT  /api/me

        Route::post('/avatar',                  [ProfileController::class, 'uploadAvatar'])
             ->name('avatar');                  // POST /api/me/avatar

        Route::put('/password',                 [ProfileController::class, 'changePassword'])
             ->name('password');                // PUT  /api/me/password

        Route::delete('/',                      [ProfileController::class, 'destroy'])
             ->name('delete');                  // DELETE /api/me

        // Profil étudiant étendu
        Route::prefix('student')->name('student.')->group(function () {
            Route::get('/',                     [StudentProfileController::class, 'show'])
                 ->name('show');                // GET  /api/me/student
            Route::put('/',                     [StudentProfileController::class, 'update'])
                 ->name('update');              // PUT  /api/me/student
            Route::post('/cv',                  [StudentProfileController::class, 'uploadCv'])
                 ->name('cv');                  // POST /api/me/student/cv
        });

        // Tableau de bord personnalisé
        Route::get('/dashboard',                [DashboardController::class, 'index'])
             ->name('dashboard');               // GET  /api/me/dashboard
    });
});


// ----------------------------------------------------------------
//  2. RÉFÉRENTIELS (publics — pas d'auth requise)
// ----------------------------------------------------------------

Route::prefix('ref')->name('ref.')->group(function () {

    // Pays
    Route::get('/countries',                    [CountryController::class, 'index'])
         ->name('countries');                   // GET /api/ref/countries

    // Villes (filtrable par pays : ?country_id=1)
    Route::get('/cities',                       [CityController::class, 'index'])
         ->name('cities');                      // GET /api/ref/cities
    Route::get('/cities/{city}',                [CityController::class, 'show'])
         ->name('cities.show');                 // GET /api/ref/cities/{id}

    // Secteurs d'activité
    Route::get('/sectors',                      [SectorController::class, 'index'])
         ->name('sectors');                     // GET /api/ref/sectors
    Route::get('/sectors/{sector}',             [SectorController::class, 'show'])
         ->name('sectors.show');                // GET /api/ref/sectors/{id}

    // Compétences
    Route::get('/skills',                       [SkillController::class, 'index'])
         ->name('skills');                      // GET /api/ref/skills
});


// ----------------------------------------------------------------
//  3. RECHERCHE & SUGGESTIONS INTELLIGENTES
// ----------------------------------------------------------------

// Recherche principale (par nom / secteur / localisation)
Route::get('/search',                           [SearchController::class, 'index'])
     ->name('search');
     // GET /api/search?q=Congo+Telecom&type=name
     // GET /api/search?q=Big+Data&type=sector
     // GET /api/search?q=Brazzaville&type=location
     // GET /api/search?q=...&type=mixed&sector_id=&city_id=&page=1

// Auto-complétion (barre de recherche — suggestions en temps réel)
Route::get('/search/autocomplete',              [AutocompleteController::class, 'suggest'])
     ->name('search.autocomplete');
     // GET /api/search/autocomplete?q=Con  → ["Congo Telecom","Congolaise de…"]

// Suggestions "Recherchées près de chez vous"
Route::get('/suggestions',                      [SuggestionController::class, 'index'])
     ->name('suggestions');
     // GET /api/suggestions?city_id=1&limit=10

Route::get('/suggestions/trending',             [SuggestionController::class, 'trending'])
     ->name('suggestions.trending');
     // GET /api/suggestions/trending


// ----------------------------------------------------------------
//  4. ENTREPRISES — Espace public (lecture)
// ----------------------------------------------------------------

Route::prefix('companies')->name('companies.')->group(function () {

    // Liste avec filtres (secteur, ville, taille, page…)
    Route::get('/',                             [CompanyPublicController::class, 'index'])
         ->name('index');
         // GET /api/companies?sector_id=2&city_id=1&size=51-200&page=2

    // Fiche détaillée entreprise (par slug)
    Route::get('/{slug}',                       [CompanyPublicController::class, 'show'])
         ->name('show');
         // GET /api/companies/congo-telecom

    // Médias (vidéos, visite 3D, galerie)
    Route::get('/{slug}/media',                 [CompanyPublicController::class, 'media'])
         ->name('media');
         // GET /api/companies/congo-telecom/media

    // Organigramme
    Route::get('/{slug}/org',                   [CompanyPublicController::class, 'org'])
         ->name('org');
         // GET /api/companies/congo-telecom/org

    // Publications / Réalisations
    Route::get('/{slug}/publications',          [CompanyPublicController::class, 'publications'])
         ->name('publications');
         // GET /api/companies/congo-telecom/publications

    Route::get('/{slug}/publications/{pub}',    [CompanyPublicController::class, 'publicationShow'])
         ->name('publications.show');
         // GET /api/companies/congo-telecom/publications/42

    // Contacts RH (email, téléphone — visibles aux connectés)
    Route::get('/{slug}/hr-contacts',           [CompanyPublicController::class, 'hrContacts'])
         ->middleware('auth:sanctum')
         ->name('hr-contacts');
         // GET /api/companies/congo-telecom/hr-contacts

    // Offres actives de cette entreprise
    Route::get('/{slug}/offers',                [JobOfferPublicController::class, 'byCompany'])
         ->name('offers');
         // GET /api/companies/congo-telecom/offers

    // Avis de cette entreprise
    Route::get('/{slug}/reviews',               [ReviewController::class, 'index'])
         ->name('reviews');
         // GET /api/companies/congo-telecom/reviews?page=1

    // Statistiques publiques (note moyenne, nb avis, nb offres…)
    Route::get('/{slug}/stats',                 [CompanyPublicController::class, 'stats'])
         ->name('stats');
         // GET /api/companies/congo-telecom/stats
});


// ----------------------------------------------------------------
//  5. ENTREPRISES — Espace privé (CRUD entreprise connectée)
// ----------------------------------------------------------------

Route::middleware(['auth:sanctum', 'role:company'])->prefix('my-company')->name('my-company.')->group(function () {

    // Lire / Créer / Mettre à jour / Supprimer la fiche
    Route::get('/',                             [CompanyController::class, 'show'])
         ->name('show');                        // GET    /api/my-company
    Route::post('/',                            [CompanyController::class, 'store'])
         ->name('store');                       // POST   /api/my-company
    Route::put('/',                             [CompanyController::class, 'update'])
         ->name('update');                      // PUT    /api/my-company
    Route::delete('/',                          [CompanyController::class, 'destroy'])
         ->name('destroy');                     // DELETE /api/my-company

    // Logo & bannière
    Route::post('/logo',                        [CompanyController::class, 'uploadLogo'])
         ->name('logo');                        // POST /api/my-company/logo
    Route::post('/cover',                       [CompanyController::class, 'uploadCover'])
         ->name('cover');                       // POST /api/my-company/cover

    // Médias
    Route::get('/media',                        [CompanyMediaController::class, 'index'])
         ->name('media.index');
    Route::post('/media',                       [CompanyMediaController::class, 'store'])
         ->name('media.store');
    Route::put('/media/{media}',                [CompanyMediaController::class, 'update'])
         ->name('media.update');
    Route::delete('/media/{media}',             [CompanyMediaController::class, 'destroy'])
         ->name('media.destroy');
    Route::post('/media/reorder',               [CompanyMediaController::class, 'reorder'])
         ->name('media.reorder');               // POST /api/my-company/media/reorder

    // Publications / Réalisations
    Route::apiResource('publications',          CompanyPublicationController::class)
         ->names('publications');
         // GET    /api/my-company/publications
         // POST   /api/my-company/publications
         // GET    /api/my-company/publications/{id}
         // PUT    /api/my-company/publications/{id}
         // DELETE /api/my-company/publications/{id}

    Route::post('/publications/{pub}/publish',  [CompanyPublicationController::class, 'publish'])
         ->name('publications.publish');
    Route::post('/publications/{pub}/unpublish',[CompanyPublicationController::class, 'unpublish'])
         ->name('publications.unpublish');

    // Organigramme
    Route::get('/org',                          [CompanyOrgController::class, 'index'])
         ->name('org.index');
    Route::post('/org',                         [CompanyOrgController::class, 'store'])
         ->name('org.store');
    Route::put('/org/{node}',                   [CompanyOrgController::class, 'update'])
         ->name('org.update');
    Route::delete('/org/{node}',                [CompanyOrgController::class, 'destroy'])
         ->name('org.destroy');
    Route::post('/org/reorder',                 [CompanyOrgController::class, 'reorder'])
         ->name('org.reorder');

    // Contacts RH
    Route::apiResource('hr-contacts',           CompanyHrContactController::class)
         ->names('hr-contacts');
         // GET    /api/my-company/hr-contacts
         // POST   /api/my-company/hr-contacts
         // GET    /api/my-company/hr-contacts/{id}
         // PUT    /api/my-company/hr-contacts/{id}
         // DELETE /api/my-company/hr-contacts/{id}

    Route::post('/hr-contacts/{contact}/primary', [CompanyHrContactController::class, 'setPrimary'])
         ->name('hr-contacts.primary');         // Définir contact principal

    // Statistiques tableau de bord entreprise
    Route::get('/dashboard',                    [CompanyController::class, 'dashboard'])
         ->name('dashboard');
         // GET /api/my-company/dashboard
});


// ----------------------------------------------------------------
//  6. OFFRES — Espace public (lecture)
// ----------------------------------------------------------------

Route::prefix('offers')->name('offers.')->group(function () {

    // Liste avec filtres
    Route::get('/',                             [JobOfferPublicController::class, 'index'])
         ->name('index');
         // GET /api/offers?type=internship&sector_id=1&city_id=2&q=data&page=1

    // Détail d'une offre (par slug)
    Route::get('/{slug}',                       [JobOfferPublicController::class, 'show'])
         ->name('show');
         // GET /api/offers/data-analyst-congo-telecom-2025

    // Offres similaires
    Route::get('/{slug}/similar',               [JobOfferPublicController::class, 'similar'])
         ->name('similar');
         // GET /api/offers/{slug}/similar
});


// ----------------------------------------------------------------
//  7. OFFRES — Espace entreprise (CRUD)
// ----------------------------------------------------------------

Route::middleware(['auth:sanctum', 'role:company'])->prefix('my-company/offers')->name('my-offers.')->group(function () {

    Route::get('/',                             [JobOfferController::class, 'index'])
         ->name('index');                       // GET    /api/my-company/offers

    Route::post('/',                            [JobOfferController::class, 'store'])
         ->name('store');                       // POST   /api/my-company/offers

    Route::get('/{offer}',                      [JobOfferController::class, 'show'])
         ->name('show');                        // GET    /api/my-company/offers/{id}

    Route::put('/{offer}',                      [JobOfferController::class, 'update'])
         ->name('update');                      // PUT    /api/my-company/offers/{id}

    Route::delete('/{offer}',                   [JobOfferController::class, 'destroy'])
         ->name('destroy');                     // DELETE /api/my-company/offers/{id}

    Route::post('/{offer}/publish',             [JobOfferController::class, 'publish'])
         ->name('publish');                     // POST   /api/my-company/offers/{id}/publish

    Route::post('/{offer}/close',               [JobOfferController::class, 'close'])
         ->name('close');                       // POST   /api/my-company/offers/{id}/close

    Route::post('/{offer}/duplicate',           [JobOfferController::class, 'duplicate'])
         ->name('duplicate');                   // POST   /api/my-company/offers/{id}/duplicate
});


// ----------------------------------------------------------------
//  8. CANDIDATURES — Côté étudiant
// ----------------------------------------------------------------

Route::middleware(['auth:sanctum', 'role:student'])->prefix('applications')->name('applications.')->group(function () {

    // Mes candidatures (liste)
    Route::get('/',                             [StudentApplicationController::class, 'index'])
         ->name('index');
         // GET /api/applications?status=pending&page=1

    // Postuler à une offre
    Route::post('/',                            [StudentApplicationController::class, 'store'])
         ->name('store');
         // POST /api/applications
         // body: { job_offer_id, company_id, cover_letter, cv_path }

    // Candidature spontanée
    Route::post('/spontaneous',                 [StudentApplicationController::class, 'storeSpontaneous'])
         ->name('spontaneous');
         // POST /api/applications/spontaneous
         // body: { company_id, cover_letter, cv_path }

    // Détail d'une candidature
    Route::get('/{application}',                [StudentApplicationController::class, 'show'])
         ->name('show');
         // GET /api/applications/{id}

    // Retirer une candidature
    Route::delete('/{application}',             [StudentApplicationController::class, 'withdraw'])
         ->name('withdraw');
         // DELETE /api/applications/{id}
});


// ----------------------------------------------------------------
//  9. CANDIDATURES — Côté entreprise / RH
// ----------------------------------------------------------------

Route::middleware(['auth:sanctum', 'role:company'])->prefix('my-company/applications')->name('company-applications.')->group(function () {

    // Toutes les candidatures reçues
    Route::get('/',                             [CompanyApplicationController::class, 'index'])
         ->name('index');
         // GET /api/my-company/applications?status=pending&offer_id=5&page=1

    // Détail d'une candidature
    Route::get('/{application}',                [CompanyApplicationController::class, 'show'])
         ->name('show');
         // GET /api/my-company/applications/{id}

    // Changer le statut d'une candidature
    Route::put('/{application}/status',         [CompanyApplicationController::class, 'updateStatus'])
         ->name('status');
         // PUT /api/my-company/applications/{id}/status
         // body: { status: "shortlisted"|"interview"|"accepted"|"rejected", note }

    // Ajouter une note interne RH
    Route::put('/{application}/notes',          [CompanyApplicationController::class, 'updateNotes'])
         ->name('notes');
         // PUT /api/my-company/applications/{id}/notes

    // Statistiques candidatures (par offre, par statut…)
    Route::get('/stats',                        [CompanyApplicationController::class, 'stats'])
         ->name('stats');
         // GET /api/my-company/applications/stats
});


// ----------------------------------------------------------------
//  10. AVIS & NOTATIONS
// ----------------------------------------------------------------

// Déposer un avis (étudiant connecté)
Route::middleware(['auth:sanctum', 'role:student'])->group(function () {

    Route::post('/companies/{slug}/reviews',    [ReviewController::class, 'store'])
         ->name('reviews.store');
         // POST /api/companies/congo-telecom/reviews

    Route::put('/reviews/{review}',             [ReviewController::class, 'update'])
         ->name('reviews.update');
         // PUT /api/reviews/{id}

    Route::delete('/reviews/{review}',          [ReviewController::class, 'destroy'])
         ->name('reviews.destroy');
         // DELETE /api/reviews/{id}
});

// Voter "utile" sur un avis (tout utilisateur connecté)
Route::middleware('auth:sanctum')->group(function () {
    Route::post('/reviews/{review}/vote',       [ReviewVoteController::class, 'toggle'])
         ->name('reviews.vote');
         // POST /api/reviews/{id}/vote  (toggle : vote / dévote)
});


// ----------------------------------------------------------------
//  11. MESSAGERIE / CHAT
// ----------------------------------------------------------------

Route::middleware('auth:sanctum')->prefix('conversations')->name('conversations.')->group(function () {

    // Liste de mes conversations
    Route::get('/',                             [ConversationController::class, 'index'])
         ->name('index');
         // GET /api/conversations

    // Démarrer une conversation
    Route::post('/',                            [ConversationController::class, 'store'])
         ->name('store');
         // POST /api/conversations
         // body: { company_id, subject }

    // Détail d'une conversation
    Route::get('/{conversation}',               [ConversationController::class, 'show'])
         ->name('show');
         // GET /api/conversations/{id}

    // Fermer / archiver une conversation
    Route::put('/{conversation}/status',        [ConversationController::class, 'updateStatus'])
         ->name('status');
         // PUT /api/conversations/{id}/status  body: { status: "closed"|"archived" }

    // Messages d'une conversation
    Route::get('/{conversation}/messages',      [MessageController::class, 'index'])
         ->name('messages.index');
         // GET /api/conversations/{id}/messages?page=1

    // Envoyer un message
    Route::post('/{conversation}/messages',     [MessageController::class, 'store'])
         ->name('messages.store');
         // POST /api/conversations/{id}/messages
         // body: { body, attachment }

    // Marquer les messages comme lus
    Route::post('/{conversation}/read',         [MessageController::class, 'markRead'])
         ->name('messages.read');
         // POST /api/conversations/{id}/read
});


// ----------------------------------------------------------------
//  12. NOTIFICATIONS
// ----------------------------------------------------------------

Route::middleware('auth:sanctum')->prefix('notifications')->name('notifications.')->group(function () {

    Route::get('/',                             [NotificationController::class, 'index'])
         ->name('index');
         // GET /api/notifications?unread=1&page=1

    Route::get('/unread-count',                 [NotificationController::class, 'unreadCount'])
         ->name('unread-count');
         // GET /api/notifications/unread-count

    Route::post('/{notification}/read',         [NotificationController::class, 'markRead'])
         ->name('read');
         // POST /api/notifications/{id}/read

    Route::post('/read-all',                    [NotificationController::class, 'markAllRead'])
         ->name('read-all');
         // POST /api/notifications/read-all

    Route::delete('/{notification}',            [NotificationController::class, 'destroy'])
         ->name('destroy');
         // DELETE /api/notifications/{id}
});


// ----------------------------------------------------------------
//  13. FAVORIS / BOOKMARKS
// ----------------------------------------------------------------

Route::middleware(['auth:sanctum', 'role:student'])->prefix('bookmarks')->name('bookmarks.')->group(function () {

    // Mes favoris
    Route::get('/',                             [BookmarkController::class, 'index'])
         ->name('index');
         // GET /api/bookmarks?type=company|job_offer

    // Ajouter aux favoris
    Route::post('/',                            [BookmarkController::class, 'store'])
         ->name('store');
         // POST /api/bookmarks
         // body: { bookmarkable_type: "company"|"job_offer", bookmarkable_id: 12 }

    // Retirer des favoris
    Route::delete('/',                          [BookmarkController::class, 'destroy'])
         ->name('destroy');
         // DELETE /api/bookmarks
         // body: { bookmarkable_type, bookmarkable_id }

    // Toggle (ajoute si absent, retire si présent)
    Route::post('/toggle',                      [BookmarkController::class, 'toggle'])
         ->name('toggle');
         // POST /api/bookmarks/toggle
});


// ----------------------------------------------------------------
//  14. ANALYTICS (lecture publique + privée)
// ----------------------------------------------------------------

// Vue enregistrée (public — appelé automatiquement par le front)
Route::post('/track/view',                      [AnalyticsController::class, 'trackView'])
     ->name('analytics.view');
     // POST /api/track/view
     // body: { viewable_type: "company"|"job_offer", viewable_id: 5 }

// Statistiques propres à l'entreprise connectée
Route::middleware(['auth:sanctum', 'role:company'])
     ->get('/my-company/analytics',             [AnalyticsController::class, 'companyStats'])
     ->name('analytics.company');
     // GET /api/my-company/analytics?period=30days


// ----------------------------------------------------------------
//  15. ADMINISTRATION
//  Middleware : auth:sanctum + role:admin
// ----------------------------------------------------------------

Route::middleware(['auth:sanctum', 'role:admin'])->prefix('admin')->name('admin.')->group(function () {

    // Tableau de bord admin
    Route::get('/dashboard',                    [AdminDashboardController::class, 'index'])
         ->name('dashboard');
         // GET /api/admin/dashboard

    // --- Utilisateurs ---
    Route::get('/users',                        [AdminUserController::class, 'index'])
         ->name('users.index');
    Route::get('/users/{user}',                 [AdminUserController::class, 'show'])
         ->name('users.show');
    Route::put('/users/{user}',                 [AdminUserController::class, 'update'])
         ->name('users.update');
    Route::post('/users/{user}/ban',            [AdminUserController::class, 'ban'])
         ->name('users.ban');
    Route::post('/users/{user}/restore',        [AdminUserController::class, 'restore'])
         ->name('users.restore');
    Route::delete('/users/{user}',              [AdminUserController::class, 'destroy'])
         ->name('users.destroy');

    // --- Entreprises ---
    Route::get('/companies',                    [AdminCompanyController::class, 'index'])
         ->name('companies.index');
    Route::get('/companies/{company}',          [AdminCompanyController::class, 'show'])
         ->name('companies.show');
    Route::put('/companies/{company}',          [AdminCompanyController::class, 'update'])
         ->name('companies.update');
    Route::post('/companies/{company}/verify',  [AdminCompanyController::class, 'verify'])
         ->name('companies.verify');
    Route::post('/companies/{company}/unverify',[AdminCompanyController::class, 'unverify'])
         ->name('companies.unverify');
    Route::delete('/companies/{company}',       [AdminCompanyController::class, 'destroy'])
         ->name('companies.destroy');

    // --- Offres ---
    Route::get('/offers',                       [AdminJobOfferController::class, 'index'])
         ->name('offers.index');
    Route::get('/offers/{offer}',               [AdminJobOfferController::class, 'show'])
         ->name('offers.show');
    Route::put('/offers/{offer}',               [AdminJobOfferController::class, 'update'])
         ->name('offers.update');
    Route::post('/offers/{offer}/activate',     [AdminJobOfferController::class, 'activate'])
         ->name('offers.activate');
    Route::post('/offers/{offer}/deactivate',   [AdminJobOfferController::class, 'deactivate'])
         ->name('offers.deactivate');
    Route::delete('/offers/{offer}',            [AdminJobOfferController::class, 'destroy'])
         ->name('offers.destroy');

    // --- Avis & Modération ---
    Route::get('/reviews',                      [AdminReviewController::class, 'index'])
         ->name('reviews.index');
    Route::post('/reviews/{review}/approve',    [AdminReviewController::class, 'approve'])
         ->name('reviews.approve');
    Route::post('/reviews/{review}/reject',     [AdminReviewController::class, 'reject'])
         ->name('reviews.reject');
    Route::delete('/reviews/{review}',          [AdminReviewController::class, 'destroy'])
         ->name('reviews.destroy');

    // --- Signalements ---
    Route::get('/reports',                      [AdminReportController::class, 'index'])
         ->name('reports.index');
    Route::get('/reports/{report}',             [AdminReportController::class, 'show'])
         ->name('reports.show');
    Route::put('/reports/{report}/status',      [AdminReportController::class, 'updateStatus'])
         ->name('reports.status');

    // --- Référentiels (gestion admin) ---
    Route::apiResource('sectors',               AdminSectorController::class)
         ->names('sectors');
         // GET/POST /api/admin/sectors
         // GET/PUT/DELETE /api/admin/sectors/{id}

    // --- Suggestions entreprises ---
    Route::get('/suggestions',                  [AdminSuggestionController::class, 'index'])
         ->name('suggestions.index');
    Route::post('/suggestions',                 [AdminSuggestionController::class, 'store'])
         ->name('suggestions.store');
    Route::put('/suggestions/{suggestion}',     [AdminSuggestionController::class, 'update'])
         ->name('suggestions.update');
    Route::delete('/suggestions/{suggestion}',  [AdminSuggestionController::class, 'destroy'])
         ->name('suggestions.destroy');

    // --- Statistiques globales ---
    Route::get('/stats',                        [AdminDashboardController::class, 'globalStats'])
         ->name('stats');
         // GET /api/admin/stats?period=7days|30days|year
});


// ================================================================
//  RÉSUMÉ DES ROUTES PAR MODULE
// ================================================================
//
//  Auth              → /api/auth/*                   (9 routes)
//  Mon profil        → /api/me/*                     (8 routes)
//  Référentiels      → /api/ref/*                    (5 routes)
//  Recherche         → /api/search/*                 (3 routes)
//  Suggestions       → /api/suggestions/*            (2 routes)
//  Entreprises pub.  → /api/companies/*              (9 routes)
//  Mon entreprise    → /api/my-company/*             (25 routes)
//  Offres pub.       → /api/offers/*                 (3 routes)
//  Mes offres        → /api/my-company/offers/*      (7 routes)
//  Candidatures stu. → /api/applications/*           (5 routes)
//  Candidatures RH   → /api/my-company/applications/* (5 routes)
//  Avis              → /api/(companies|reviews)/*    (5 routes)
//  Chat              → /api/conversations/*          (7 routes)
//  Notifications     → /api/notifications/*          (5 routes)
//  Bookmarks         → /api/bookmarks/*              (4 routes)
//  Analytics         → /api/track/*                  (2 routes)
//  Administration    → /api/admin/*                  (30 routes)
//
//  TOTAL ≈ 144 routes API  +  1 route SPA (web.php)
// ================================================================
