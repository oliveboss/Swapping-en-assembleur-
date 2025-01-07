; Fait par Rémi Thorez & Amouzou Koffitsé Fiadupé

option casemap:none

includelib ucrt.lib
includelib legacy_stdio_definitions.lib
includelib kernel32.lib

extrn printf:proc
extrn scanf:proc
extrn VirtualAlloc:proc
extrn VirtualFree:proc

extrn CreateFileA:PROC
extrn ReadFile:PROC

extrn ExitProcess:PROC
extrn GetLastError:PROC
extrn CloseHandle:PROC

; Raccourci compilation : ml64 projet_final_code.asm /link /subsystem:console /entry:main

;--- Debbuger ---
	; call GetLastError
	
	; lea rcx, msgCodeErreur
	; mov rdx, rax
	
	; sub rsp,40
	; call printf
	; add rsp,40
;--- Debbuger ---

;--- Debbuger ---
	; lea rcx, msgDebug2
	
	; sub rsp,40
	; call printf
	; add rsp,40
;--- Debbuger ---

.data

	;------------------------------- Messages d'interaction avec l'utilisateur ---------------------------------------
	
    msgDebutAffectation DB "Debut de l'affectation de la memoire vive et de la memoire virtuelle.",  0Ah , 0   ; Message d'allocation en cours
    msgErreurLecture db "Erreur lors de la lecture du fichier.", 0
	msgErreurAffectation DB "Erreur ! : Echec de l'affectation de la memoire !", 0Ah, 0 
    msgAffectationVRam DB " La memoire virtuelle est alloue a : 0x%p ", 0Ah,0Ah, 0 ; Message pour afficher l'adresse
	msgAffectationRam DB " La RAM est alloue  a : 0x%p ", 0Ah, 0 
	msgChoix1 DB "Entrez 1 pour ouvrir un programme et 0 pour le fermer :",0
	msgChoix2 DB "Entrez le numero du programme que vous voulez executer (choisir entre 0 et 4) : ", 0
	msgErreurEntree DB "Entrer invalide. Veuillez entrer un numero valide.", 0
	msgCodeErreur db "Code d'erreur : %d", 0
	msgHangleFichier db "Handle du fichier : %d",0Ah, 0
	msgOuvertureFichier db "Fichier ouvert avec succes",0Ah, 0
	msgErreurOuverture db "Erreur lors de l'ouverture du fichier",0
	msgOpDejaFait db "L'operation selectionner est deja active",10,0
	
	titreAffichageFichiers DB "Liste des programmes disponibles :", 0Ah,0Ah, 0
	
	msgEtatVRam db " VRam : |", 0
	msgEtatRam db "Ram : |", 0
	msgFinLigne db " ",10,0
	
	
	;------------------------------- Fin des messages d'interaction avec l'utilisateur ---------------------------------------
	
	;-------------------- Format de string ------------------------------------
	
	formatLecture db "Lecture reussie : %s",0Ah, 0
	formatEntreeProgramme DB "%d", 0 ; Format pour lire une chaîne avec scanf
	formatAffichageFichier db "%d: %s , etat: %d",10,0
	formatRamVram db "%d|",0
	
	;-------------------- Fin des format de string ---------------------------
	
	;--------------------- Variables ----------------------------------
	
	ram_base dq 0
	ram_size dq 1000h     	; Taille de la RAM simulée (4 Ko)

	vram_base dq 0
    vram_size dq 2800h     	; Taille de la mémoire virtuelle (10 Ko)
    
	tableauFichiers DB "programmes/addition.txt", 0 
            DB "programmes/soustraction.txt", 0
            DB "programmes/multiplication.txt", 0
            DB "programmes/division.txt", 0
            DB "programmes/affectation.txt", 0
	
	tableauEtatRam qword 8 DUP(-1) ; 512 o / bloc ; -1 = une case vide sinon c'est le numéro du programme qui occupe ce bloc
	
	tableauEtatVRam qword 20 DUP(-1) ; 512 o / bloc ; -1 = une case vide sinon c'est le numéro du programme qui occupe ce bloc
	
	tableauHandles qword 5 DUP(0)
			  
	tableauEtat sdword 5 dup (0) ; 0 = Fermé, 1 = En cours exécution, 2 = Ouvert, 3 = En VRam

	bufferChemin db 1024 dup(0)
	bufferFichier db 256 dup(0)
	limiteBuffer qword 256
	
	;--------------------- Fin des variables ----------------------------------
	
	;--------------------- Valeurs statics ---------------------
	
	INVALID_HANDLE_VALUE equ -1

	GENERIC_READ equ 80000000h
    GENERIC_WRITE equ 40000000h
    FILE_SHARE_READ equ 1
    FILE_SHARE_WRITE equ 2
    OPEN_EXISTING equ 3
    FILE_ATTRIBUTE_NORMAL equ 128
	PAGE_READONLY dq 02h
	PAGE_READWRITE dq 04h
	MEM_RESERVE dq 2000h
	MEM_COMMIT dq 1000h
	MEM_RELEASE dq 8000h
	MEM_DECOMMIT dq 4000h
	

	;--------------------- Fin des valeurs statics ---------------------
	
	
	; ------------------- Assignation ----------------------------------
	tailleBloc dq 512
	tailleAAssigner dq ?
	nbBloc dq ?
	index1Bloc dq ?

	nbBlocASwapper dq ?
	index1BlocRam dq -1
	index1BlocVRam dq ?
	numero_programme_en_cours_swap qword ?
	; ------------------ Fin d'assignation ----------------------------
	
	msgDebug db "%d ", 10,0
	msgDebug2 db "Working ", 10,0
	msgDebugS db "%s ",10,0
	
	
.data?
	
	numero_programme qword ?
	typeAction sdword ? ; 0 ou 1; 0 = fermeture du programme et 1 = ouverture du programme
    bytesLue dword ? 

.const
	
.code

main PROC

	; ----------------------- Initialisation --------------------------
	
    ; Afficher le message "Allocation de La Ram et d'une memoire virtuelle "
    lea rcx, msgDebutAffectation
    
	sub rsp,40
	call printf  ; Afficher le message
	add rsp, 40 

    ; === Réserver la RAM simulée ===
    mov rcx, ram_base
    mov rdx, ram_size
    mov r8, MEM_RESERVE
    mov r9, PAGE_READWRITE
	
    sub rsp,40
    call VirtualAlloc
    add rsp,40
	
	; Appel à l'API VirtualAlloc
    test rax, rax              ; Vérifier si l'allocation a réussi
    jz erreur_affectation         ; Si échec, aller à AllocationError
    
	lea rcx, msgAffectationRam 		   ; Charger le message d'allocation réussie
	mov rdx,rax
	
	sub rsp,40
	call printf ; Afficher l'adresse allouée 
	add rsp, 40 

	xor rax,rax

    ; === Réserver la memoire virtuelle simulée ===
    mov rcx,vram_base
    mov rdx, vram_size
    mov r8, MEM_RESERVE
    mov r9, PAGE_READWRITE
    
	sub rsp,40; 
    call VirtualAlloc 
    add rsp,40 
    
	test rax, rax              ; Vérifier si l'allocation a réussi
    jz erreur_affectation

    ; Si l'allocation réussie, afficher l'adresse allouée pour la mémoire virtuelle
    
    lea rcx, msgAffectationVRam ; Charger le message d'allocation réussie
	mov rdx,rax
	
	sub rsp,40
	call printf 			   ; Afficher l'adresse allouée 
	add rsp, 40 
    
	jmp affichage_liste
	
erreur_affectation:
   lea rcx, msgErreurAffectation
  
   sub rsp,40
   call printf 
   add rsp,40
   
	; ----------------------- Fin Initialisation --------------------------
	
	; ----------------------- Affichage -----------------------------------
	
affichage_liste:

	lea rcx, msgEtatRam
	sub rsp,40
	call printf
	add rsp,40
	
	lea rbx, tableauEtatRam
	
	xor rdi,rdi
	
debut_afficher_tableau_ram:
	lea rcx, formatRamVram
	mov rdx, [rbx+rdi*8]

	sub rsp,40
	call printf
	add rsp,40

	inc rdi
	cmp rdi,8
	jge fin_afficher_tableau_ram
	jmp debut_afficher_tableau_ram

fin_afficher_tableau_ram:
	lea rcx, msgEtatVRam
	sub rsp,40
	call printf
	add rsp,40

	lea rbx, tableauEtatVRam
	
	xor rdi,rdi
	
debut_afficher_tableau_vram:
	lea rcx, formatRamVram
	mov rdx, [rbx+rdi*8]

	sub rsp,40
	call printf
	add rsp,40

	inc rdi
	cmp rdi,20
	jge fin_afficher_tableau_vram
	jmp debut_afficher_tableau_vram

fin_afficher_tableau_vram:

	lea rcx, msgFinLigne
	sub rsp,40
	call printf
	add rsp,40

    lea rcx, titreAffichageFichiers
	
    sub rsp, 40
    call printf
    add rsp, 40
	
    lea rsi, tableauFichiers
	lea rbx, tableauEtat
	xor rdi,rdi
	xor r9,r9

afficher_table_fichier:
	mov al, [rsi]
    test al, al
    jz affichageInstruction 

    lea rcx, formatAffichageFichier
	mov rdx,rdi
	mov r8,rsi
	mov r9d,[rbx + rdi*4]

    sub rsp, 40
    call printf
    add rsp, 40

	
aller_fichier_suivant:

	inc rsi
	cmp BYTE PTR [rsi],0
	jnz aller_fichier_suivant
	inc rsi
	inc rdi
	cmp rdi, 5
    jl afficher_table_fichier
	
affichageInstruction:	
	
	xor rdi, rdi
	xor rax, rax
	
boucleChercherActif:
	lea rcx, tableauEtat
	mov eax, [rcx + rdi*4]
	cmp eax, 1
	je trouverActif
	inc rdi
	cmp rdi, 5
	jge fin_affichage
	jmp boucleChercherActif
	
trouverActif:
	
		;---------------------- Afficher programme actif ----------------------
	lea rbx, tableauHandles
	mov rax, [rbx + rdi*8]
	
	cmp rax,0
	je fin_affichage
	
	mov rcx, QWORD ptr [rbx + rdi*8]
    lea rdx, bufferFichier
    mov r8, limiteBuffer
	xor r9,r9
	
	sub rsp, 40	
    call ReadFile
    add rsp, 40
	
	test rax, rax
    jz erreurLecture
	
	lea rbx, bufferFichier
	xor rsi,rsi
	xor rdi, rdi

	lea rcx, bufferFichier
	
	sub rsp,40
	call printf
	add rsp,40
	
	lea rcx, msgFinLigne
	sub rsp,40
	call printf
	add rsp,40

		;---------------------- Fin afficher programme actif ----------------------
fin_affichage:

	; ----------------------- Fin Affichage -----------------------------------

	; ----------------------- Demande entrée utilisateur ----------------------

	
demandeChoix2:
	lea rcx, msgChoix2
	
	sub rsp,40
	call printf
	add rsp,40
	
	lea rcx, formatEntreeProgramme
    lea rdx,numero_programme
    sub rsp,40
    call scanf
    add rsp,40
	
	mov rax,numero_programme
	
	cmp rax,0
	jl demandeChoix2
	cmp rax,4
	jg demandeChoix2
	
demandeChoix1:
	lea rcx, msgChoix1
	
	sub rsp,40
	call printf
	add rsp,40
	
	lea rcx, formatEntreeProgramme
    lea rdx,typeAction
    sub rsp,40
    call scanf
    add rsp,40
	
	xor rax, rax
	mov eax,typeAction
	
	cmp eax,0
	je demandeFermeture
	cmp eax,1
	je demandeOuverture
	jmp demandeChoix1
	
	; ----------------------- Fin de la demande entrée utilisateur ----------------------

	; ----------------------- Gestion d'ouverture d'un programme ----------------------------

deja:

	lea rcx, msgOpDejaFait
	
	sub rsp,40
	call printf
	add rsp,40
	
	jmp affichage_liste

demandeOuverture:
	xor rcx,rcx
	mov rax, numero_programme
	lea rbx, tableauEtat
	mov ecx, [rbx + rax*4]
	
	cmp ecx, 0 ; S'il est fermé
	je ouvrir
	
	cmp ecx, 1 ; S'il est déja en cours d'exécution
	je deja ;
	
	cmp ecx, 2 ; S'il est ouvert mais pas en cours d'exécution
	je changerCoursExec
	
	cmp ecx, 3 ; S'il est présentement swappé
	je swappe
	
		; ------------------------ Gestion de l'action à effectuer pour l'ouverture -----------------
erreurOuverture:
	
	lea rcx, msgErreurOuverture
	
	sub rsp,40
	call printf
	add rsp,40
	
	jmp terminer

erreurLecture:
	lea rcx, msgErreurLecture
	
	sub rsp,40
	call printf
	add rsp,40
	jmp terminer
erreurMemoire:
	lea rcx, msgErreurAffectation
	
	sub rsp,40
	call printf
	add rsp,40
	jmp terminer
	
ouvrir:
		;--------------------------------- Vérification et mise d'autrui en VRAM -----------------------------------------
	
		;--------------------------------- Fin de la vérification et mise d'autrui en VRAM -------------------------------
	call mettreEnCoursOuvert
	
	mov ecx, 1
	mov rax, numero_programme
	mov [rbx + rax*4], ecx
	
		; -------------------------------- Mise en RAM -----------------------------------
		
	call extraireCheminFichier

	sub rsp, 56
	lea rcx, bufferChemin
	mov rdx, GENERIC_READ
	mov r8, FILE_SHARE_READ
    mov r9, 0
	MOV QWORD PTR [RSP+32], OPEN_EXISTING
	MOV QWORD PTR [RSP+40], FILE_ATTRIBUTE_NORMAL
	MOV QWORD PTR [RSP+48], 0

    call CreateFileA
    add rsp, 56

	cmp rax, INVALID_HANDLE_VALUE
	je erreurOuverture
	
	;----- Enregistrement du handle -----
	lea rbx, tableauHandles 
	mov rdi, numero_programme
	mov [rbx + rdi*4], rax
	;----- Fin de l'enregistrement du handle -----

	mov rcx, QWORD ptr [rbx + rdi*8]
    lea rdx, bufferFichier
    mov r8, limiteBuffer
	xor r9,r9
	
	sub rsp, 40	
    call ReadFile
    add rsp, 40
	

	test rax, rax
    jz erreurLecture
	
	lea rbx, bufferFichier
	xor rsi,rsi
	xor rdi, rdi
	xor rax,rax
	
extraireTaille:
	mov al, [rbx+rsi]
	cmp al, 10
	je tailleExtraite
	
	cmp al, '0'
	jl tailleExtraite

	sub al, '0'
	
	imul rdi, rdi, 10
	add rdi, rax
	inc rsi
	jmp extraireTaille

tailleExtraite:
	
	mov tailleAAssigner, rdi
	mov r8,tailleAAssigner

avant_boucleVerifRam:
	lea rcx, tableauEtatRam
	xor rsi,rsi
	xor rbx, rbx
	xor rdx, rdx

boucleVerifierRam:

	mov rbx, [rcx+rsi*8]

	cmp rbx, -1
	je vide
	inc rsi
	mov rdx,0
	cmp rsi,8
	jge swapper
	jmp boucleVerifierRam
	
vide:
	cmp rdx,0
	jne skip3
	mov index1Bloc,rsi
skip3:
	inc rdx

	mov rax, tailleBloc
	imul rdx ; L'erreur est ici

	cmp rax,r8
	jge assezEspaceRam
	inc rsi
	cmp rsi,8
	jge swapper
	jmp boucleVerifierRam
	
assezEspaceRam:
	mov nbBloc,rdx
	xor rax,rax
	mov rax, numero_programme

boucleAssignationRam:
	mov [rcx + rsi*8], rax
	dec rdx
	cmp rdx, 0
	je finAssignationRam
	dec rsi
	jmp boucleAssignationRam

finAssignationRam:
	
	mov rax,512
	mov rbx, index1Bloc 
	imul rbx
	
	mov rcx, ram_base
	add rcx, rax
    mov rdx, tailleAAssigner
    mov r8, MEM_COMMIT
    mov r9, PAGE_READONLY
	
    sub rsp,40
    call VirtualAlloc
    add rsp,40
	
	test rax,rax
	jz erreur_affectation

	jmp affichage_liste
	
swapper:
	
	lea rcx, tableauEtatRam
	xor rdi, rdi
	xor rdx, rdx
	
boucle_swapper_trouver_prog:
	mov rax, [rcx +rdi*8]
	cmp rax, -1
	je emplacementVide
	
	cmp rdx,0
	jne skip
	mov numero_programme_en_cours_swap, rax
	mov index1BlocRam,rdi
skip:
	mov rbx, numero_programme_en_cours_swap
	cmp rbx,rax
	jne finObtenirInfoProg
	inc rdi
	inc rdx
	jmp boucle_swapper_trouver_prog


emplacementVide:
	cmp rdx,0
	jne finObtenirInfoProg
	inc rdi
	cmp rdi,8
	jge terminer
	jmp boucle_swapper_trouver_prog
	
finObtenirInfoProg:

	mov nbBlocASwapper, rdx
	
boucleDesassignationRam:
	mov rax,-1
	mov [rcx + rdi*8], rax
	dec rdx
	cmp rdx, 0
	je finDesssignationRam
	dec rdi
	jmp boucleDesassignationRam

finDesssignationRam:

	mov rax,512
	mov rdx, nbBlocASwapper
	imul rdx
	
	mov rax, 512
	mov rcx, index1BlocRam
	imul rcx
	
	mov rcx, vram_base
	add rcx, rax
	mov rdx, rax
	mov r8, MEM_DECOMMIT
	
	sub rsp,40
	call VirtualFree
	add rsp,40
	
	lea rcx, tableauEtatVRam
	xor rdi,rdi
	xor rdx,rdx
	
debutAssignationVRam:
	mov rax, [rcx +rdi*8]
	cmp rax,-1
	je emplacementVideAssignationVRam
	mov rdx,0
	inc rdi ; Pas besoin de chercher plus loin dans ce contexte et si la vram est pleine et bien laisser le mourir
	jmp debutAssignationVRam
finAssignationVRam:
	
emplacementVideAssignationVRam:
	cmp rdx,0
	jne skip2
	mov index1BlocVRam, rdi
skip2:
	inc rdx
	mov rax,512
	mov rbx,nbBlocASwapper
	imul rbx
	mov rbx, rax
	mov rax,512
	imul rdx
	cmp rax, rbx
	jge assezEspaceEnVram
	inc rdi
	jmp debutAssignationVRam
assezEspaceEnVram:
	mov rdi, index1BlocVRam
	mov rdx, nbBlocASwapper
	mov rax, numero_programme_en_cours_swap
	mov [rcx +rdi*8], rax
	dec rdi
	dec rdx
	cmp rdx,0
	jg assezEspaceEnVram
	
	mov rax,512
	mov rbx, index1BlocVRam 
	imul rbx
	
	mov rcx, vram_base
	add rcx, rax
	mov rax, 512
	mov rdx, nbBlocASwapper
	imul rdx
	mov rdx,rax
    mov r8, MEM_COMMIT
    mov r9, PAGE_READWRITE
	
    sub rsp,40
    call VirtualAlloc
    add rsp,40
	
	test rax,rax
	jz erreur_affectation
	
	lea rcx, tableauEtat
	xor rax,rax
	mov eax,3
	mov rdx, numero_programme_en_cours_swap
	mov [rcx+ rdx*4], eax
	
	jmp avant_boucleVerifRam
	
changerCoursExec:

	call mettreEnCoursOuvert

	mov ecx, 1
	mov rax, numero_programme
	mov [rbx + rax*4], ecx
	
	jmp affichage_liste
			; -------------------------------- Fin de la mise en RAM -----------------------------------
			

swappe:

	call mettreEnCoursOuvert
	
	mov ecx, 1
	mov rax, numero_programme
	mov [rbx + rax*4], ecx
	
	lea rcx, tableauEtatVRam
	xor rdi, rdi
	xor rdx, rdx
	mov rbx, numero_programme
boucle_obtenir_info_VRam:

	mov rax, [rcx+rdi*8]
	cmp rax, rbx
	je progVramTrouver
	cmp rdx,0
	jne finProgVram
	inc rdi
	jmp boucle_obtenir_info_VRam
	
progVramTrouver:
	cmp rdx,0
	jne skip6
	mov index1Bloc, rdi
skip6:
	inc rdx
	mov rax,-1
	mov [rcx+rdi*8], rax
	inc rdi
	cmp rdi,20
	jge finProgVram

finProgVram:
	mov nbBloc, rdx
	
	mov rax,512
	mov rdx, nbBloc
	imul rdx
	
	mov rax, 512
	mov rcx, index1Bloc
	imul rcx
	
	mov rcx, vram_base
	add rcx, rax
	mov rdx, rax
	mov r8, MEM_DECOMMIT
	
	sub rsp,40
	call VirtualFree
	add rsp,40
	
	mov rax,512
	mov rbx,nbBloc
	imul rbx
	
	mov tailleAAssigner, rax
	
	jmp avant_boucleVerifRam
	
		; ------------------------ Fin de la gestion de l'action à effectuer pour l'ouverture -----------------
	; ----------------------- Fin de la gestion d'ouverture d'un programme ----------------------------

	; ----------------------- Gestion de la fermeture d'un programme ------------------------

demandeFermeture:
	xor rcx,rcx
	mov rax, numero_programme
	lea rbx, tableauEtat
	mov ecx, [rbx +rax*4]
	
	cmp ecx, 0; S'il est déjà fermé
	je deja
	
	cmp ecx, 1; S'il est en cours d'exécution
	je fermer
	
	cmp ecx, 2; S'il est ouvert dans la ram
	je fermer
	
	cmp ecx, 3; S'il est ouvert dans la VRAM
	je fermerSwapper
		
		; ------------------------ Gestion de l'action à effectuer pour la fermeture -----------------
		
fermer:
	mov ecx, 0
	mov [rbx + rax*4], ecx
	
	lea rcx, tableauEtatRam
	xor rdi, rdi
	xor rdx, rdx
	mov rbx, numero_programme
	mov r8,-1
fermerRam:
	
	mov rax, [rcx+rdi*8]
	cmp rax, rbx
	je programmeAEnleverRam
	cmp rdx,0
	jne finFermerRam
	inc rdi
	jmp fermerRam
	
programmeAEnleverRam:
	mov [rcx+rdi*8], r8
	cmp rdx,0
	jne skip4
	mov index1Bloc, rdi
	skip4:
	inc rdx
	inc rdi
	cmp rdi,8
	jge finFermerRam
	jmp fermerRam
finFermerRam:
	mov nbBloc, rdx	
	
	mov rax,512
	mov rdx, nbBloc
	imul rdx
	
	mov rax, 512
	mov rcx, index1Bloc
	imul rcx
	
	mov rcx, ram_base
	add rcx, rax
	mov rdx, rax
	mov r8, MEM_DECOMMIT
	
	sub rsp,40
	call VirtualFree
	add rsp,40
	
	lea rbx, tableauHandles
	mov rax, numero_programme
	
	lea rcx, [rbx+rax*8]
	call CloseHandle

	jmp affichage_liste
	
	; ---------------------- --------------
	
fermerSwapper:
	mov ecx, 0
	mov [rbx + rax*4], ecx	
		lea rcx, tableauEtatVRam
	xor rdi, rdi
	xor rdx, rdx
	mov rbx, numero_programme
	mov r8,-1
fermerVRam:
	
	mov rax, [rcx+rdi*8]
	cmp rax, rbx
	je programmeAEnleverVRam
	cmp rdx,0
	jne finFermerVRam
	inc rdi
	jmp fermerVRam
	
programmeAEnleverVRam:
	mov [rcx+rdi*8], r8
	cmp rdx,0
	jne skip5
	mov index1Bloc, rdi
	skip5:
	inc rdx
	inc rdi
	cmp rdi,20
	jge finFermerVRam
	jmp fermerVRam
finFermerVRam:
	mov nbBloc, rdx	
	
	mov rax,512
	mov rdx, nbBloc
	imul rdx
	
	mov rax, 512
	mov rcx, index1Bloc
	imul rcx
	
	mov rcx, vram_base
	add rcx, rax
	mov rdx, rax
	mov r8, MEM_DECOMMIT
	
	sub rsp,40
	call VirtualFree
	add rsp,40
	
	lea rbx, tableauHandles
	mov rax, numero_programme
	
	lea rcx, [rbx+rax*8]
	call CloseHandle

	jmp affichage_liste
	
		; ------------------------ Fin  de la gestion de l'action à effectuer pour la fermeture -----------------
	; ----------------------- Fin de la gestion de la fermeture d'un programme ------------------------

terminer:
	lea rbx, tableauHandles
	xor rdi,rdi
fermer_handle:
	mov rax, [rbx +rdi*8]
	
	cmp rax, 0
	je deja_fermer
	
	
	lea rcx, [rbx+rdi*8]
	call CloseHandle
	
deja_fermer:
	inc rdi
	cmp rdi,5
	jge fin_fermer_handles
	jmp fermer_handle

fin_fermer_handles:

	mov rcx, ram_base
	mov rdx, 0
	mov r8, MEM_RELEASE
	
	sub rsp,40
	call VirtualFree
	add rsp,40

	mov rcx, vram_base
	mov rdx, 0
	mov r8, MEM_RELEASE
	
	sub rsp,40
	call VirtualFree
	add rsp,40

sub rsp, 40
call ExitProcess                       
add rsp, 40

main ENDP

mettreEnCoursOuvert PROC
	push rdi
	push rbx
	
	xor rdi, rdi
	xor rax, rax
	xor rbx,rbx
	
boucleChercherEnCours:
	lea rcx, tableauEtat
	mov eax, [rcx + rdi*4]
	cmp eax, 1
	je trouverEnCours
	inc rdi
	cmp rdi, 5
	jge fin
	jmp boucleChercherEnCours
	
trouverEnCours:
	mov ebx,2
	mov [rcx +rdi*4], ebx
	
fin:
	pop rbx
	pop rdi
	
	ret
	
mettreEnCoursOuvert ENDP

extraireCheminFichier PROC

    push rsi
    push rdi

    lea rsi, tableauFichiers
    xor rdi, rdi
    mov rax, numero_programme
    
chercher_fichier:
    cmp rdi, rax
    je fichier_trouve
    
    inc rsi
    cmp BYTE PTR [rsi], 0
    jnz chercher_fichier
    inc rsi
    inc rdi
    jmp chercher_fichier
    
fichier_trouve:
    lea rdi, bufferChemin
	
copier_chemin:

    mov al, [rsi]
    mov [rdi], al
    inc rsi
    inc rdi
    cmp al, 0
    jnz copier_chemin

    pop rdi
    pop rsi
    ret
	
extraireCheminFichier ENDP

END