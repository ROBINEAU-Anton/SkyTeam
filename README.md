# Sky Team - Adaptation Numérique (FPP)

Ce projet est une adaptation numérique immersive du jeu de plateau **Sky Team**. Contrairement à une version 2D classique, cette version propose une vue subjective (First Person Perspective) au sein du cockpit pour une immersion totale.

## 🛩️ Résumé du Jeu
**Sky Team** est un jeu coopératif pour deux joueurs (un Pilote et un Co-pilote) dont l'objectif est de faire atterrir un avion de ligne dans différents aéroports du monde.

---

## 📜 Règles du Jeu (Implémentation Obligatoire)

### 1. Structure d'une Partie
Une partie se déroule en **7 manches** maximum, représentant la descente de l'appareil de 6 000 pieds jusqu'au sol. Chaque manche suit 3 phases :
1.  **Discussion Stratégique & Lancer de Dés** : Les joueurs discutent de la manche, puis lancent leurs 4 dés en secret. Une fois les dés lancés, le **silence total** est requis.
2.  **Pose des Dés** : Les joueurs placent un dé à tour de rôle sur le tableau de bord jusqu'à ce que les 8 dés soient posés.
3.  **Fin de Manche** : L'avion descend de 1 000 pieds. Si l'altitude atteint 0, la phase d'atterrissage finale est déclenchée.

### 2. Actions Obligatoires (Chaque Manche)
Chaque joueur DOIT placer un dé sur les deux zones suivantes avant la fin de la manche :
*   **L'Axe (Équilibre)** : Le Pilote et le Co-pilote placent chacun un dé. La différence entre les deux valeurs fait incliner l'avion. L'aiguille ne doit jamais atteindre la zone de vrille (X).
*   **Les Réacteurs (Vitesse)** : La somme des deux dés (Pilote + Co-pilote) détermine la distance parcourue sur la piste d'approche (0, 1 ou 2 cases) en fonction des marqueurs d'aérodynamisme actuels.

### 3. Actions Secondaires
*   **Radio** : Permet de retirer des avions de la piste d'approche. La valeur du dé indique la distance à laquelle l'avion est dégagé.
*   **Trains d'atterrissage (Pilote uniquement)** : Doivent être tous déployés avant l'atterrissage. Chaque train sorti augmente la traînée.
*   **Volets (Co-pilote uniquement)** : Doivent être déployés dans l'ordre (de haut en bas). Ils augmentent la portance/traînée.
*   **Freins (Pilote uniquement)** : Permettent d'augmenter la capacité de freinage pour l'atterrissage final.
*   **Concentration (Café)** : Permet d'obtenir des jetons pour modifier la valeur d'un dé de +/- 1.

### 4. Conditions de Défaite Immédiate
*   Collision avec un autre avion sur la piste d'approche.
*   L'avion part en vrille (Axe atteint la limite X).
*   L'avion dépasse l'aéroport (trop de vitesse).
*   L'avion touche le sol avant d'avoir atteint l'aéroport.
*   Oubli d'une action obligatoire (Axe ou Réacteurs).

### 5. Conditions de Victoire (Dernière Manche)
Pour réussir l'atterrissage à 0 pied, les conditions suivantes doivent être réunies :
1.  **Approche** : Aucun avion ne doit se trouver sur la piste.
2.  **Configuration** : Tous les trains d'atterrissage et les volets sont déployés.
3.  **Équilibre** : L'axe de l'appareil est parfaitement horizontal.
4.  **Vitesse** : La puissance des réacteurs est strictement **inférieure** à la puissance de freinage déployée.

---

## 🛠️ Stack Technique & Architecture
*Consulter le [Rapport d'Architecture](./docs/architecture_report.md) pour plus de détails sur le choix du moteur (Unity/Godot/Web).*
