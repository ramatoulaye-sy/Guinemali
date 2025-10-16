# Script de vérification de la configuration Firebase
# Pour Guinemali

Write-Host ""
Write-Host "🔥 VÉRIFICATION DE LA CONFIGURATION FIREBASE" -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan
Write-Host ""

$allGood = $true

# 1. Vérifier que google-services.json existe
Write-Host "1. Vérification de google-services.json..." -NoNewline
if (Test-Path "android\app\google-services.json") {
    Write-Host " ✅ TROUVÉ" -ForegroundColor Green
    
    # Vérifier que le fichier n'est pas vide
    $fileSize = (Get-Item "android\app\google-services.json").Length
    if ($fileSize -gt 100) {
        Write-Host "   Taille : $fileSize octets" -ForegroundColor Gray
    } else {
        Write-Host "   ⚠️ ATTENTION : Le fichier semble vide ou corrompu" -ForegroundColor Yellow
        $allGood = $false
    }
    
    # Vérifier le contenu
    try {
        $content = Get-Content "android\app\google-services.json" -Raw | ConvertFrom-Json
        $packageName = $content.client[0].client_info.android_client_info.package_name
        
        if ($packageName -eq "com.guinemali.mobile") {
            Write-Host "   Package name : $packageName ✅" -ForegroundColor Green
        } else {
            Write-Host "   ⚠️ ATTENTION : Package name incorrect : $packageName" -ForegroundColor Yellow
            Write-Host "   Attendu : com.guinemali.mobile" -ForegroundColor Yellow
            $allGood = $false
        }
        
        $projectId = $content.project_info.project_id
        Write-Host "   Project ID : $projectId" -ForegroundColor Gray
        
    } catch {
        Write-Host "   ⚠️ Impossible de lire le contenu du fichier" -ForegroundColor Yellow
        $allGood = $false
    }
} else {
    Write-Host " ❌ NON TROUVÉ" -ForegroundColor Red
    Write-Host "   Le fichier doit être dans : android\app\google-services.json" -ForegroundColor Yellow
    $allGood = $false
}

Write-Host ""

# 2. Vérifier build.gradle.kts (root)
Write-Host "2. Vérification de android/build.gradle.kts..." -NoNewline
if (Test-Path "android\build.gradle.kts") {
    $content = Get-Content "android\build.gradle.kts" -Raw
    if ($content -like "*google-services*") {
        Write-Host " ✅ CONFIGURÉ" -ForegroundColor Green
        Write-Host "   Plugin Google Services détecté" -ForegroundColor Gray
    } else {
        Write-Host " ⚠️ MANQUANT" -ForegroundColor Yellow
        Write-Host "   Plugin Google Services non trouvé" -ForegroundColor Yellow
        $allGood = $false
    }
} else {
    Write-Host " ❌ FICHIER NON TROUVÉ" -ForegroundColor Red
    $allGood = $false
}

Write-Host ""

# 3. Vérifier app/build.gradle.kts
Write-Host "3. Vérification de android/app/build.gradle.kts..." -NoNewline
if (Test-Path "android\app\build.gradle.kts") {
    $content = Get-Content "android\app\build.gradle.kts" -Raw
    
    $checks = @{
        "Plugin Google Services" = "*com.google.gms.google-services*"
        "Firebase BOM" = "*firebase-bom*"
        "Firebase Messaging" = "*firebase-messaging*"
    }
    
    $allChecksPass = $true
    foreach ($check in $checks.GetEnumerator()) {
        if ($content -like $check.Value) {
            # OK
        } else {
            $allChecksPass = $false
            break
        }
    }
    
    if ($allChecksPass) {
        Write-Host " ✅ CONFIGURÉ" -ForegroundColor Green
        Write-Host "   Toutes les dépendances Firebase détectées" -ForegroundColor Gray
    } else {
        Write-Host " ⚠️ INCOMPLET" -ForegroundColor Yellow
        foreach ($check in $checks.GetEnumerator()) {
            if ($content -like $check.Value) {
                Write-Host "   ✅ $($check.Key)" -ForegroundColor Green
            } else {
                Write-Host "   ❌ $($check.Key)" -ForegroundColor Red
            }
        }
        $allGood = $false
    }
} else {
    Write-Host " ❌ FICHIER NON TROUVÉ" -ForegroundColor Red
    $allGood = $false
}

Write-Host ""

# 4. Vérifier pubspec.yaml
Write-Host "4. Vérification de pubspec.yaml..." -NoNewline
if (Test-Path "pubspec.yaml") {
    $content = Get-Content "pubspec.yaml" -Raw
    
    $packages = @("firebase_core", "firebase_messaging")
    $allPackagesPresent = $true
    
    foreach ($package in $packages) {
        if ($content -notlike "*$package*") {
            $allPackagesPresent = $false
            break
        }
    }
    
    if ($allPackagesPresent) {
        Write-Host " ✅ CONFIGURÉ" -ForegroundColor Green
        Write-Host "   Packages Firebase détectés" -ForegroundColor Gray
    } else {
        Write-Host " ⚠️ INCOMPLET" -ForegroundColor Yellow
        foreach ($package in $packages) {
            if ($content -like "*$package*") {
                Write-Host "   ✅ $package" -ForegroundColor Green
            } else {
                Write-Host "   ❌ $package" -ForegroundColor Red
            }
        }
        $allGood = $false
    }
} else {
    Write-Host " ❌ FICHIER NON TROUVÉ" -ForegroundColor Red
    $allGood = $false
}

Write-Host ""

# 5. Vérifier lib/firebase_options.dart
Write-Host "5. Vérification de lib/firebase_options.dart..." -NoNewline
if (Test-Path "lib\firebase_options.dart") {
    Write-Host " ✅ TROUVÉ" -ForegroundColor Green
    Write-Host "   Fichier de configuration Firebase présent" -ForegroundColor Gray
} else {
    Write-Host " ❌ NON TROUVÉ" -ForegroundColor Red
    $allGood = $false
}

Write-Host ""

# 6. Vérifier lib/core/services/fcm_service.dart
Write-Host "6. Vérification de lib/core/services/fcm_service.dart..." -NoNewline
if (Test-Path "lib\core\services\fcm_service.dart") {
    Write-Host " ✅ TROUVÉ" -ForegroundColor Green
    Write-Host "   Service FCM implémenté" -ForegroundColor Gray
} else {
    Write-Host " ❌ NON TROUVÉ" -ForegroundColor Red
    $allGood = $false
}

Write-Host ""
Write-Host "=============================================" -ForegroundColor Cyan

if ($allGood) {
    Write-Host ""
    Write-Host "✅ CONFIGURATION FIREBASE COMPLÈTE !" -ForegroundColor Green
    Write-Host ""
    Write-Host "Prochaines étapes :" -ForegroundColor Cyan
    Write-Host "1. Récupérer la clé serveur FCM depuis Firebase Console" -ForegroundColor White
    Write-Host "2. Déployer sur Supabase avec : .\deploy_supabase.ps1" -ForegroundColor White
    Write-Host "3. Rebuilder l'app : flutter clean && flutter build apk --release" -ForegroundColor White
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "⚠️ CONFIGURATION INCOMPLÈTE" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Consultez le guide : GUIDE_CONFIGURATION_FIREBASE_VISUEL.md" -ForegroundColor White
    Write-Host ""
}

# Attendre une touche avant de fermer
Write-Host "Appuyez sur une touche pour continuer..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
