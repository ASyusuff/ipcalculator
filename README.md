## root user
```
chmod +X ip.sh
```
```
./ip.sh
```
Perbaiki Format File

Jika script dibuat di Windows, bisa muncul error karakter ^M.
Gunakan perintah berikut untuk memperbaiki:
```
sed -i 's/\r$//' namafile.sh
```
atau
```
dos2unix namafile.sh
```
