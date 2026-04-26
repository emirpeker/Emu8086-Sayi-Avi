org 100h

; ======================================================================
; OYUN SABÝTLERÝ (Oyun boyunca asla deðiþmeyecek sýnýrlar)
; ======================================================================
ALAN_SOL_SINIR equ 21       ; Oyun alanýnýn sol duvar koordinatý
ALAN_SAG_SINIR equ 59       ; Oyun alanýnýn sað duvar koordinatý
ALAN_UST_SINIR equ 6        ; Oyun alanýnýn üst (tavan) koordinatý
ALAN_ALT_SINIR equ 19       ; Oyun alanýnýn alt (zemin) koordinatý

; ======================================================================
; BAÞLANGIÇ AYARLARI VE GÝRÝÞ EKRANI
; ======================================================================
    ; 1) Ekraný metin moduna alýyoruz
    mov ah, 00h
    mov al, 03h             ; 80x25 Standart renkli metin modu
    int 10h

    ; 2) Yanýp sönen rahatsýz edici imleci gizliyoruz
    mov ah, 01h             
    mov ch, 20h             ; CH=20h imleci görünmez yapar
    int 10h
      
    ; 3) Baþlangýç Yazýlarýný (Title Screen) Ekrana Basýyoruz
    mov dh, 10              ; Satýr 10
    mov dl, 34              ; Sütun 34 (Ortalama)
    call imleci_konumlandir ; Ýmleci oraya taþý
    mov dx, offset str_baslik ; Baþlýk metninin adresini al
    call metin_yazdir       ; Ekrana bas

    mov dh, 13
    mov dl, 25
    call imleci_konumlandir
    mov dx, offset str_basla
    call metin_yazdir

    ; 4) Oyuncunun "Baþlamak için bir tuþa basmasýný" bekliyoruz
    mov ah, 00h             ; Klavye bekleme kesmesi (Tuþa basana kadar oyun durur)
    int 16h
    
    ; 5) Tuþa basýldý! Ekraný temizle ve oyunun duvarlarýný (çerçeveyi) çiz
    call ekrani_temizle
    call cerceve_ciz

; ======================================================================
; ANA OYUN DÖNGÜSÜ (Oyun bitene kadar saniyede onlarca kez döner)
; ======================================================================
oyun_dongusu:

    ; ------------------------------------------------------------------
    ; 1. ZAMANLAYICI (Timer) KONTROLÜ
    ; ------------------------------------------------------------------
    ; Assembly çok hýzlý olduðu için süreyi birden düþemeyiz.
    ; Önce bir "gecikme sayacýný" azaltýyoruz. O sýfýrlanýrsa 1 saniye düþüyoruz.
    dec sure_gecikmesi        
    jnz sure_guncellemeyi_atla   
    
    ; Sayaç sýfýrlandý! Yeni gecikme deðerini ata. 
    ; (Oyun hýzlandýkça bu deðer artar ki saniye yine gerçek saniye gibi aksýn)
    mov al, sayac_yenileme
    mov sure_gecikmesi, al   
    
    dec kalan_sure          ; Gerçek süreyi 1 saniye azalt
    jz oyun_kaybedildi      ; Süre 0 (Zero) olduysa oyunu bitir!

sure_guncellemeyi_atla:

    ; ------------------------------------------------------------------
    ; 2. SAYILARIN HAREKETÝ VE ESKÝ YERLERÝNÝN SÝLÝNMESÝ
    ; ------------------------------------------------------------------
    mov si, 0               ; si = 0, 1, 2, 3 (Dört farklý sayý için indeks)

sayi_hareket_dongusu:
    ; Eski koordinatlara gidip boþluk (' ') basarak eski sayýyý siliyoruz
    mov dh, sayi_y_konum[si]
    mov dl, sayi_x_konum[si]
    call imleci_konumlandir
    mov al, ' '             
    call standart_yazi_yaz
    
    ; Eðer sildiðimiz sayý negatifse (örn -9) iki karakter kaplar, yanýndakini de sil
    cmp sayi_degerleri[si], 0
    jge silme_islemi_tamam  ; Sayý pozitifse atla
    inc dl                  ; Sütunu 1 artýr (saðdaki karakter)
    call imleci_konumlandir
    mov al, ' '
    call standart_yazi_yaz

silme_islemi_tamam:
    ; Yatay (X) Hareket ve Çarpýþma Kontrolü
    mov al, sayi_x_konum[si]
    add al, sayi_x_hiz[si]  ; Konuma hýzý ekle
    cmp al, ALAN_SAG_SINIR  ; Sað duvara çarptý mý?
    jge x_sinirina_carpti
    cmp al, ALAN_SOL_SINIR  ; Sol duvara çarptý mý?
    jle x_sinirina_carpti
    jmp x_degerini_kaydet

x_sinirina_carpti: 
    neg sayi_x_hiz[si]      ; Hýzý ters çevir (1 ise -1 yap, sekme etkisi)
    add al, sayi_x_hiz[si]  

x_degerini_kaydet: 
    mov sayi_x_konum[si], al ; Yeni X konumunu kaydet

    ; Dikey (Y) Hareket ve Çarpýþma Kontrolü
    mov al, sayi_y_konum[si]
    add al, sayi_y_hiz[si]
    cmp al, ALAN_ALT_SINIR
    jge y_sinirina_carpti
    cmp al, ALAN_UST_SINIR
    jle y_sinirina_carpti
    jmp y_degerini_kaydet

y_sinirina_carpti: 
    neg sayi_y_hiz[si]      ; Dikeyde sekme etkisi
    add al, sayi_y_hiz[si]

y_degerini_kaydet: 
    mov sayi_y_konum[si], al ; Yeni Y konumunu kaydet

    ; Sonraki sayýya geç
    inc si
    cmp si, 4
    jl sayi_hareket_dongusu

    ; ------------------------------------------------------------------
    ; 3. OYUNCU HAREKETÝ (Klavye Dinleme)
    ; ------------------------------------------------------------------
    ; Oyuncunun ekrandaki eski 'P' harfini sil
    mov dh, oyuncu_y
    mov dl, oyuncu_x
    call imleci_konumlandir
    mov al, ' '
    call standart_yazi_yaz

    ; Klavyeden tuþa basýlýp basýlmadýðýný kontrol et (Oyun durmadan arka planda)
    mov ah, 01h
    int 16h
    jz hareket_yok          ; Tuþa basýlmadýysa hareketi atla
    
    ; Tuþa basýldýysa hangi tuþ olduðunu oku
    mov ah, 00h
    int 16h
    cmp al, 'w'
    je yukari_git
    cmp al, 's'
    je asagi_git
    cmp al, 'a'
    je sola_git
    cmp al, 'd'
    je saga_git
    cmp al, 27              ; ESC tuþu (Çýkýþ)
    je oyunu_kapat
    jmp hareket_yok

yukari_git: 
    cmp oyuncu_y, ALAN_UST_SINIR
    jle hareket_yok         ; Tavana yapýþtýysa gitme
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

    ; ------------------------------------------------------------------
    ; 4. ÇARPIÞMA ALGISI VE SAYILARIN ÇÝZÝMÝ
    ; ------------------------------------------------------------------
    mov si, 0
sayilari_ekrana_ciz:
    ; Oyuncu (P) ile ekrandaki sayýnýn koordinatlarý ayný mý?
    mov al, oyuncu_y
    cmp al, sayi_y_konum[si]
    jne sayi_cizimine_gec   ; Y koordinatý uymuyorsa çarpmamýþtýr
    
    mov al, oyuncu_x
    cmp al, sayi_x_konum[si]
    je carpisma_algilandi   ; X koordinatý da tam uyuyorsa çarpmýþtýr!
    
    ; Negatif sayýlar 2 karakter olduðu için "saðdan çarpma" kontrolü
    cmp sayi_degerleri[si], 0
    jge sayi_cizimine_gec
    mov al, oyuncu_x
    dec al 
    cmp al, sayi_x_konum[si]
    jne sayi_cizimine_gec

carpisma_algilandi:
    ; Çarpýlan sayýnýn deðerini anlýk skora ekle
    mov al, anlik_skor
    add al, sayi_degerleri[si]
    mov anlik_skor, al
    
    ; Yeni skorumuz hedefi geçti mi? (Level atlama kontrolü)
    cmp al, hedef_skor
    jge sonraki_tura_gec
    
    ; Sayýyý yakaladýk, ona yeni rastgele bir deðer verip ortaya ýþýnla
    call rastgele_sayi_uret 

sayi_cizimine_gec:
    ; Ýmleci sayýnýn koordinatlarýna taþý
    mov dh, sayi_y_konum[si]
    mov dl, sayi_x_konum[si]
    call imleci_konumlandir
    
    ; Sayýnýn deðerini kontrol et (Pozitif mi Negatif mi?)
    mov al, sayi_degerleri[si]
    cmp al, 0
    jl negatif_yazdir       
    
    ; Pozitifleri Yeþil Renk (0Ah) ile çiz
    add al, 48              ; Rakamý ASCII karakterine çevir (+48)
    mov bl, 0Ah
    call renkli_yazi_yaz
    jmp dongu_sonraki_sayi

negatif_yazdir:
    ; Negatifleri Kýrmýzý Renk (0Ch) ve eksi iþaretiyle çiz
    push ax
    mov al, '-'             
    mov bl, 0Ch
    call renkli_yazi_yaz
    pop ax
    neg al                  ; Sayýyý pozitife çevir (örn: -3'ü 3 yap)
    add al, 48
    inc dl                  ; Bir saða kayýp rakamý yazdýr
    call imleci_konumlandir
    call renkli_yazi_yaz

dongu_sonraki_sayi:
    inc si
    cmp si, 4
    jl sayilari_ekrana_ciz

    ; Oyuncuyu (P) Sarý Renkle (0Eh) Çiz
    mov dh, oyuncu_y
    mov dl, oyuncu_x
    call imleci_konumlandir
    mov al, 'P'
    mov bl, 0Eh
    call renkli_yazi_yaz

    ; ------------------------------------------------------------------
    ; 5. ÜST BÝLGÝ PANELÝ (Skor ve Süre Yazýlarý)
    ; ------------------------------------------------------------------
    ; Sol Üst: SKOR
    mov dh, 0
    mov dl, 5
    call imleci_konumlandir
    mov dx, offset str_skor
    call metin_yazdir
    
    mov al, anlik_skor
    call skoru_ekrana_yaz
    mov al, '/'
    call standart_yazi_yaz
    mov al, hedef_skor
    call sayiyi_ekrana_yaz

    ; Sað Üst: SÜRE
    mov dh, 0
    mov dl, 45       
    call imleci_konumlandir
    mov dx, offset str_sure
    call metin_yazdir
    
    mov al, kalan_sure
    call sayiyi_ekrana_yaz

    ; ------------------------------------------------------------------
    ; OYUN HIZI (GECÝKME)
    ; ------------------------------------------------------------------
    ; Bu bölüm oyunun ne kadar hýzlý aktýðýný belirler.
    ; DX deðeri azaldýkça oyun hýzlanýr. Biz bunu level atladýkça düþürüyoruz!
    mov cx, 00h
    mov dx, oyun_hizi       
    mov ah, 86h
    int 15h
    
    jmp oyun_dongusu        ; Ana döngünün baþýna dön

; ======================================================================
; OYUN DURUM KONTROLLERÝ (Level Atlama ve Oyun Bitiþleri)
; ======================================================================
sonraki_tura_gec:
    ; Eðer 5. turu da geçerse oyun tamamen kazanýlýr
    cmp mevcut_tur, 5
    jge oyun_kazanildi

    ; Verileri Yeni Tur Ýçin Güncelle
    inc mevcut_tur
    add hedef_skor, 5       ; Hedef her turda +5 artar
    mov kalan_sure, 15      ; Süre tekrar 15 saniyeden baþlar
    mov anlik_skor, 0       ; Kazanýlan puan sýfýrlanýr
    
    ; --- HER TURDA HIZLANMA MANTIÐI ---
    sub oyun_hizi, 0350h    ; Bekleme süresini (DX) azaltýr. Oyun HIZLANIR! (Her turda çalýþýr)
    inc sayac_yenileme      ; Döngü hýzlandýðý için 1 saniyenin süresini dengeler
    ; ----------------------------------

    ; Oyuncuyu güvenli bölgeye (ortaya) al
    mov oyuncu_x, 40
    mov oyuncu_y, 12

    call ekrani_temizle
    
    ; Ara ekran: "X. TUR BASLIYOR"
    mov dh, 11
    mov dl, 30
    call imleci_konumlandir
    mov al, mevcut_tur
    add al, 48              ; Rakamý ASCII'ye çevir
    call standart_yazi_yaz
    mov dx, offset str_tur
    call metin_yazdir

    ; Tur ekranýný oyuncuya 1-2 saniye göster
    mov cx, 000Fh
    mov dx, 0000h
    mov ah, 86h
    int 15h

    ; Yeni tur baþlýyor, çerçeveyi çiz ve ana döngüye dön
    call ekrani_temizle
    call cerceve_ciz
    jmp oyun_dongusu

oyun_kazanildi:
    call ekrani_temizle
    
    mov dh, 10
    mov dl, 33
    call imleci_konumlandir
    mov dx, offset str_kazandin
    call metin_yazdir

    mov dh, 14
    mov dl, 31
    call imleci_konumlandir
    mov dx, offset str_harika
    call metin_yazdir

    jmp son_skoru_yazdir

oyun_kaybedildi:
    call ekrani_temizle
    
    mov dh, 10
    mov dl, 31
    call imleci_konumlandir
    mov dx, offset str_kaybettin
    call metin_yazdir

    mov dh, 14
    mov dl, 28
    call imleci_konumlandir
    mov dx, offset str_hizli
    call metin_yazdir

son_skoru_yazdir:
    ; Oyun bitince hangi skorda kaldýðýný ortaya yazdýrýr
    mov dh, 12
    mov dl, 34
    call imleci_konumlandir
    mov dx, offset str_skor
    call metin_yazdir
    
    mov al, anlik_skor
    call skoru_ekrana_yaz

kapatilmayi_bekle:
    ; Oyun bitti, çýkmak için klavyeden tuþ beklenir
    mov ah, 00h
    int 16h 
oyunu_kapat:
    ret                     ; Programý sonlandýr ve MS-DOS'a dön

; ======================================================================
; YARDIMCI FONKSÝYONLAR (Tekrarlayan iþleri yapan alt programlar)
; ======================================================================
metin_yazdir:
    ; DX'te verilen bellek adresindeki yaziyi '$' isaretini görene kadar ekrana yazar
    mov bp, dx
metin_dongusu:
    mov al, [bp]
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
    ; Ekranýn tamamýný temizler ve renk sýzmalarýný engellemek için beyaz yazý formatýný zorlar
    mov ax, 0600h   
    mov bh, 0Fh     
    mov cx, 0000h   
    mov dx, 184Fh   
    int 10h
    ret

skoru_ekrana_yaz: 
    ; Eksi deðerlere düþebilen skoru düzgün basabilmek için özel matematik fonksiyonu
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
    mov bl, 10
    div bl                  ; Onlar basamaðýný bulmak için 10'a böl
    push ax
    add al, 48
    cmp al, '0'
    je onlar_basamagi_atla  ; Tek haneli sayýlarda baþa 0 koyma (örn: 05 yerine 5 yaz)
    call standart_yazi_yaz
onlar_basamagi_atla:
    pop ax
    mov al, ah              ; Kalaný (birler basamaðýný) yaz
    add al, 48
    call standart_yazi_yaz
    mov al, ' '             
    call standart_yazi_yaz
    pop bx
    pop ax
    ret

sayiyi_ekrana_yaz: 
    ; Her zaman pozitif olan (Süre gibi) sayýlarý yazdýrma fonksiyonu
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
    ; Oyun alanýnýn dýþýna '#' sembolü ile duvarlar örer
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
    ; Karakteri varsayýlan (Beyaz) renkte basar
    mov ah, 0eh
    mov bl, 0Fh    
    int 10h
    ret

renkli_yazi_yaz:
    ; Karakteri BL yazmacýndaki (örn: Kýrmýzý veya Yeþil) renge göre basar
    mov ah, 09h
    mov bh, 0
    mov cx, 1
    int 10h
    ret

rastgele_sayi_uret: 
    ; Bilgisayarýn saatine baðlanarak -9 ile 9 arasýnda rastgele puan üretir
    mov ah, 00h
    int 1Ah                 ; Sistem saatini (Tick) al
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