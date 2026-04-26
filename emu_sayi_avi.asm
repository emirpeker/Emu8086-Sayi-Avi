org 100h ; 100h adresinden itibaren çalýþmaya baþlar

ALAN_SOL_SINIR equ 21; equ= sabitler alansolsýnýr a 21 yazar ramde yer kaplamaz
ALAN_SAG_SINIR equ 59; 
ALAN_UST_SINIR equ 6;
ALAN_ALT_SINIR equ 19;

mov ah, 00h ;ekraný metin moduna al
mov al, 03h; 80x25 standart renkli metin modu
int 10h;  BIOS'un Video (Ekran) servisidir. Bu servise ne yapacaðýný AH yazmacýna verdiðimiz deðerle söyleriz.

mov ah, 01h;
mov ch, 20h; imleci görünmez yaoar
int 10h

mov dh, 10    ;koordinatlar
mov dl, 34
call imleci_konumlandir
mov dx, offset str_baslik
call metin_yazdir

mov dh,13
mov dl,25
call imleci_konumlandir
mov dx, offset str_basla
call metin_yazdir

mov ah,00h
int 16h

call ekrani_temizle
call cerceve_ciz

oyun_dongusu:
    dec sure_gecikmesi           ;gecikme süreyi azaltýr
    jnz sure_guncellemeyi_atla             ;0 deðilse güncellemeyi atlar
    
    mov al,sayac_yenileme        ;yeni gecikme deðeri atanýr
    mov sure_gecikmesi,al
    dec kalan_sure               ;gerçek süre düþer
    jz oyun_kaybedildi            ;0 olursa oyun kaybedilir

sure_guncellemeyi_atla:
    mov si,0                     ;ilk sayý seçilir

sayi_hareket_dongusu:
    mov dh, sayi_y_konum[si]    ;koordinatlara gidip boþlkuk yazýp siler
    mov dl, sayi_x_konum[si]    
    call imleci_konumlandir
    mov al, ' '
    call standart_yazi_yaz
    
    cmp sayi_degerleri[si],0    ;negatif mi
    jge silme_islemi_tamam      ;pozitifse bitti
    inc dl                      ;satýr arttýrýr
    call imleci_konumlandir
    mov al,' '
    call standart_yazi_yaz

silme_islemi_tamam:
    mov al, sayi_x_konum[si]
    add al, sayi_x_hiz[si]     ; ileri gittiysen 30+1 geriyse 30-1
    cmp al, ALAN_SAG_SINIR
    jge x_sinirina_carpti
    cmp al, ALAN_SOL_SINIR
    jle x_sinirina_carpti
    jmp x_degerini_kaydet 

x_sinirina_carpti:              
    neg sayi_x_hiz[si]
    add al, sayi_x_hiz[si]

x_degerini_kaydet:
    mov sayi_x_konum[si],al

    mov al, sayi_y_konum[si]
    add al, sayi_y_hiz[si]
    cmp al, ALAN_ALT_SINIR
    jge y_sinirina_carpti
    cmp al, ALAN_UST_SINIR
    jle y_sinirina_carpti
    jmp y_degerini_kaydet

y_sinirina_carpti:
    neg sayi_y_hiz[si]
    add al, sayi_y_hiz[si]

y_degerini_kaydet:
    mov sayi_y_konum[si],al
    inc si           ;diðer sayýya geç
    cmp si,4
    jl sayi_hareket_dongusu
    
    mov dh,oyuncu_y
    mov dl,oyuncu_x
    call imleci_konumlandir
    mov al,' '  
    call standart_yazi_yaz
    
    mov ah,01h
    int 16h
    jz hareket_yok
    
    mov ah,00h
    int 16h
    cmp al,'w'
    je yukari_git
    cmp al,'s'
    je asagi_git
    cmp al,'a'
    je sola_git      
    cmp al,'d'
    je saga_git
    cmp al,27  ;esc tuþu çýkýþ
    je oyunu_kapat
    jmp hareket_yok 

yukari_git:
    cmp oyuncu_y, ALAN_UST_SINIR
    jle hareket_yok ;tavana yapýþtýysa gitme
    dec oyuncu_y
    jmp hareket_yok        

asagi_git:
    cmp oyuncu_y, ALAN_ALT_SINIR
    jge hareket_yok
    inc oyuncu_y
    jmp hareket_yok

sola_git:
    cmp oyuncu_x, ALAN_SOL_SINIR
    jle hareket_yok
    dec oyuncu_x
    jmp hareket_yok 

saga_git:
    cmp oyuncu_x, ALAN_SAG_SINIR
    jge hareket_yok
    inc oyuncu_x

hareket_yok:
    mov si,0

sayilari_ekrana_ciz:
    mov al,oyuncu_y
    cmp al, sayi_y_konum[si]
    jne sayi_cizimine_gec
    
    mov al, oyuncu_x     
    cmp al,sayi_x_konum[si]
    je carpisma_algilandi
    
    cmp sayi_degerleri[si],0
    jge sayi_cizimine_gec
    mov al, oyuncu_x
    dec al
    cmp al, sayi_x_konum[si]          
    jne sayi_cizimine_gec         

carpisma_algilandi:
    mov al, anlik_skor
    add al, sayi_degerleri[si]
    mov anlik_skor, al
    cmp al, hedef_skor
    jge sonraki_tura_gec
    call rastgele_sayi_uret

sayi_cizimine_gec:
    mov dh, sayi_y_konum[si]
    mov dl, sayi_x_konum[si]
    call imleci_konumlandir
    mov al,sayi_degerleri[si]
    cmp al,0
    jl negatif_yazdir
    add al,48          ; ASCII 48=0  48+5= 5
    mov bl,0Ah
    call renkli_yazi_yaz
    jmp dongu_sonraki_sayi 

negatif_yazdir:
    push ax
    mov al,'-'
    mov bl, 0ch
    call renkli_yazi_yaz
    pop ax
    neg al
    add al,48
    inc dl
    call imleci_konumlandir
    call renkli_yazi_yaz
    
dongu_sonraki_sayi:
    inc si
    cmp si,4
    jl sayilari_ekrana_ciz
    
    mov dh,oyuncu_y   
    mov dl, oyuncu_x
    call imleci_konumlandir
    mov al, 'P'
    mov bl, 0Eh
    call renkli_yazi_yaz
    
    ; SKOR YAZISI BÖLÜMÜ
    mov dh,0
    mov dl,5
    call imleci_konumlandir
    mov dx, offset str_skor
    call metin_yazdir
    mov al, anlik_skor
    call skoru_ekrana_yaz
    mov al, '/'
    call standart_yazi_yaz
    mov al,hedef_skor
    call sayiyi_ekrana_yaz
    
    ; SÜRE YAZISI BÖLÜMÜ
    mov dh,0
    mov dl,45
    call imleci_konumlandir
    mov dx, offset str_sure
    call metin_yazdir                  
    mov al, kalan_sure          
    call sayiyi_ekrana_yaz
    
    mov cx,00h
    mov dx,oyun_hizi
    mov ah,86h
    int 15h
    
    jmp oyun_dongusu
            
sonraki_tura_gec:
    cmp mevcut_tur, 5
    jge oyun_kazanildi
    
    inc mevcut_tur
    add hedef_skor, 5
    mov kalan_sure, 15
    mov anlik_skor,0
    
    sub oyun_hizi, 0350h      ; oyunu hýzlandýrma olayý
    inc sayac_yenileme
    
    mov oyuncu_x, 40
    mov oyuncu_y, 12
    call ekrani_temizle
    
    mov dh,11
    mov dl, 30
    call imleci_konumlandir
    mov al, mevcut_tur
    add al,48
    call standart_yazi_yaz
    mov dx, offset str_tur              ;"x.tur baþlýyor" 
    call metin_yazdir
    
    mov cx, 000Fh                      ;yazýnýn okunabilmesi için bekleme süresi
    mov dx, 0000h
    mov ah, 86h
    int 15h         
    call ekrani_temizle
    call cerceve_ciz
    jmp oyun_dongusu      

oyun_kazanildi:
    call ekrani_temizle
    
    mov dh,10
    mov dl,33
    call imleci_konumlandir
    mov dx,offset str_kazandin
    call metin_yazdir
    
    mov dh,14
    mov dl,31
    call imleci_konumlandir
    mov dx, offset str_harika
    call metin_yazdir
    
    jmp son_skoru_yazdir          

oyun_kaybedildi:
    call ekrani_temizle
    
    mov dh,10
    mov dl,31
    call imleci_konumlandir
    mov dx, offset str_kaybettin
    call metin_yazdir

    mov dh,14
    mov dl,28
    call imleci_konumlandir
    mov dx, offset str_hizli
    call metin_yazdir

son_skoru_yazdir:
    mov dh,12
    mov dl,34
    call imleci_konumlandir
    mov dx, offset str_skor
    call metin_yazdir
    mov al, anlik_skor
    call skoru_ekrana_yaz

kapatilmayi_bekle:
    mov ah,00h
    int 16h

oyunu_kapat:
    ret
    
    
metin_yazdir:
    mov bp,dx

metin_dongusu:
    mov al,[bp]
    cmp al, '$'
    je metin_bitti
    mov ah, 0Eh
    mov bl, 0Fh
    int 10h
    inc bp
    jmp metin_dongusu

metin_bitti:
    ret                                

ekrani_temizle:
    mov ax, 0600h
    mov bh, 0Fh
    mov cx, 0000h
    mov dx, 184Fh                  
    int 10h
    ret

skoru_ekrana_yaz:
    push ax
    push bx
    cmp al, 0
    jge pozitif_skor_yazdir
    push ax
    mov al, '-'
    call standart_yazi_yaz
    pop ax
    neg al

pozitif_skor_yazdir:
    mov ah, 0
    mov bl,10
    div bl
    push ax
    add al,48
    cmp al,'0'
    je onlar_basamagi_atla
    call standart_yazi_yaz
onlar_basamagi_atla:
    pop ax
    mov al, ah
    add al,48
    call standart_yazi_yaz
    mov al, ' '                 
    call standart_yazi_yaz
    pop bx
    pop ax
    ret

sayiyi_ekrana_yaz: 
    ; Her zaman pozitif olan sayýlarý yazdýrma fonksiyonu
    mov ah, 0
    mov bl, 10
    div bl
    push ax
    add al, 48
    call standart_yazi_yaz
    pop ax
    mov al, ah
    add al, 48
    call standart_yazi_yaz
    mov al, ' '
    call standart_yazi_yaz
    ret

cerceve_ciz:
    
    mov dl, ALAN_SOL_SINIR - 1
ust_alt_ciz:
    mov dh, ALAN_UST_SINIR - 1
    call imleci_konumlandir
    mov al, '#'
    call standart_yazi_yaz
    mov dh, ALAN_ALT_SINIR + 1
    call imleci_konumlandir
    mov al, '#'
    call standart_yazi_yaz
    inc dl
    cmp dl, ALAN_SAG_SINIR + 1
    jle ust_alt_ciz
    mov dh, ALAN_UST_SINIR
yanlari_ciz:
    mov dl, ALAN_SOL_SINIR - 1
    call imleci_konumlandir
    mov al, '#'
    call standart_yazi_yaz
    mov dl, ALAN_SAG_SINIR + 1
    call imleci_konumlandir
    mov al, '#'
    call standart_yazi_yaz
    inc dh
    cmp dh, ALAN_ALT_SINIR
    jle yanlari_ciz
    ret

imleci_konumlandir:
    ; Yazýnýn ekranda nereye basýlacaðýný DX(DH=Satýr, DL=Sütun) deðerine göre ayarlar
    mov ah, 02h
    mov bh, 0
    int 10h
    ret

standart_yazi_yaz:
    ; Karakteri varsayýlan renkte basar
    mov ah, 0eh
    mov bl, 0Fh    
    int 10h
    ret

renkli_yazi_yaz:
    ; Karakteri BL yazmacýndaki renge göre basar
    mov ah, 09h
    mov bh, 0
    mov cx, 1
    int 10h
    ret

rastgele_sayi_uret: 
    ; Bilgisayarýn saatine baðlanarak -9 ile 9 arasýnda rastgele puan üretir
    mov ah, 00h
    int 1Ah                 ; Sistem saatini al
    mov ax, dx
    xor dx, dx
    mov cx, 19
    div cx                  ; Saati 19'a böl, kalaný (0-18) al
    mov ax, dx
    sub ax, 9               ; Kalandan 9 çýkararak -9 ile 9 aralýðýna oturt
    mov sayi_degerleri[si], al
    mov sayi_x_konum[si], 40 ; Yeni sayýyý ekranýn ortasýna koy
    mov sayi_y_konum[si], 12
    ret

; ======================================================================
; OYUN VERÝLERÝ (Deðiþkenler, Diziler ve Metinler)
; ======================================================================

oyuncu_x        db 30   
oyuncu_y        db 10   
anlik_skor      db 0    
kalan_sure      db 15   
sure_gecikmesi  db 2    
mevcut_tur      db 1    
hedef_skor      db 5    

; Yeni Eklenen Hýz Deðiþkenleri
oyun_hizi       dw 1500h   ; Oyunun baþlangýç bekleme süresi (Sayý düþtükçe hýzlanýr)
sayac_yenileme  db 3       ; Oyun hýzlandýðýnda 1 saniyenin dengesini koruyan çarpan

; Ekrandaki 4 Sayýnýn Bilgileri
sayi_x_konum    db 25, 40, 55, 30  
sayi_y_konum    db 7,  10, 15, 18  
sayi_x_hiz      db 1,  0, -1,  0   
sayi_y_hiz      db 0,  1,  0, -1   
sayi_degerleri  db 5, -3,  7, -9   

; Ekrana yazdýrýlacak kalýp metinler ('$' karakteri cümlenin bittiðini ifade eder)
str_baslik      db 'S A Y I   A V I$'
str_basla       db 'Baslamak Icin Bir Tusa Bas...$'
str_skor        db 'SKOR : $'
str_sure        db 'SURE : $'
str_kazandin    db 'K A Z A N D I N !$'
str_harika      db 'H A R I K A S I N !$'
str_kaybettin   db 'S U R E  B I T T I$'
str_hizli       db 'D A H A  H I Z L I  O L !$'
str_tur         db '.  T U R  B A S L I Y O R$'