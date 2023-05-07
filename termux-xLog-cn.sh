#!/data/data/com.termux/files/usr/bin/bash
if [ `getprop ro.build.version.release` -lt 7 ]; then
        echo "Android versions below 7 are not supported!"
        exit 1
fi
clear
rm -rf ~/xLog/
echo Installing dependencies...
pkg upd -y
pkg upgr -y
pkg i git libvips redis postgresql nodejs goose patch python python-pip binutils xorgproto x11-repo -y

pip3 config set global.index-url https://pypi.doubanio.com/simple
if [ -d "~/xLog" ];then
        echo Removing old xLog directory...
        rm -rf ~/xLog
fi
echo Cloning repository...
cd $HOME
git clone https://github.com/Crossbell-Box/xLog xLog
cd ~/xLog
clear
echo Installing pnpm...
npm config set registry https://registry.npmmirror.com/ --global
npm i -g pnpm
clear
echo Replacing include paths...
sed -i 's/<glib-object.h>/<glib-2.0\/glib-object.h>/g' $PREFIX/include/vips/vips8
sed -i 's/<glib\//<glib-2.0\/glib\//g' $PREFIX/include/glib-2.0/glib.h
sed -i 's/<gobject/<glib-2.0\/gobject/g' $PREFIX/include/glib-2.0/glib-object.h
clear
echo Installing node.js modules...
pnpm config set registry https://registry.npmmirror.com/ --global
pnpm config set sharp_binary_host "https://npmmirror.com/mirrors/sharp"
pnpm config set sharp_libvips_binary_host "https://npmmirror.com/mirrors/sharp-libvips"
pnpm i
clear
echo Setting postgresql...
mkdir -p $PREFIX/var/lib/postgresql
initdb $PREFIX/var/lib/postgresql
pg_ctl -D $PREFIX/var/lib/postgresql start --silent > /dev/null
createuser --superuser --pwprompt postgres -W password
createdb indexer
clear
echo Migrating database to postgresql...
cd prisma/migrations/20230329170038_/
mv migration.sql 001_migration.sql
sed -i '/--/d' 001_migration.sql
sed -i '1i-- +goose Up' 001_migration.sql
sed -i '$a-- +goose Down' 001_migration.sql
goose postgres "user=postgres password=password dbname=indexer sslmode=disable" up
cd ../20230329184315_/
mv migration.sql 002_migration.sql
sed -i '/--/d' 001_migration.sql
sed -i '/\/\*/,/\*\//d' 002_migration.sql
sed -i '1i-- +goose Up' 002_migration.sql
sed -i '$a-- +goose Down' 002_migration.sql
goose postgres "user=postgres password=password dbname=indexer sslmode=disable" up
cd ../20230329235052_/
mv migration.sql 003_migration.sql
sed -i '/--/d' 001_migration.sql
sed -i '1i-- +goose Up' 003_migration.sql
sed -i '$a-- +goose Down' 003_migration.sql
goose postgres "user=postgres password=password dbname=indexer sslmode=disable" up
cd ~/xLog/
echo Running redis...
redis-server &
clear
echo Exporting Run Script...
echo "#!/data/data/com.termux/files/usr/bin/bash' > ~/xLog/run.sh
echo 'cd ~/xLog' >> ~/xLog/run.sh
echo 'redis-server | pg_ctl -D $PREFIX/var/lib/postgresql start --silent | pnpm dev' >> ~/xLog/run.sh
chmod +x ~/xLog/run.sh
clear
echo Running xLog...
mv .env.example .env
pnpm dev
