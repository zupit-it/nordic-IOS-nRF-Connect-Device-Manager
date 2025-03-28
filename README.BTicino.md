2025.03.27 Aggiornamento 

Al momento  so lavorando con 3 repo remoti: 
- origin: quello ufficiale in sola lettura per scaricare gli aggiornamenti 
- bticino: la copia su bitbucket con gli aggiornamenti per le librerie di binding (su branch separato `maui-upload-manager` per tenere sempre `main` allineato)  
- zupit: copia di backup per sicurezza

bticino	git@bticino.bitbucket.org:bticinogit/nrf-connect-device-manager-ios.git
origin	git@github.com:NordicSemiconductor/IOS-nRF-Connect-Device-Manager.git
zupit	git@github.com:zupit-it/nordic-IOS-nRF-Connect-Device-Manager.git

```sh
git checkout main 
git pull origin 
git push bticino
git checkout maui-upload-manager
git rebase -i main 
[fix errors]
git commit -m "fix: updated for XCode 16"
git push -u bticino maui-upload-manager
```

