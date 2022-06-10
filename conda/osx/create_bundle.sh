# assume we have a working conda available

export MAMBA_NO_BANNER=1
env_dir="APP/FreeCAD.app/Contents/Resources"

mamba create \
    -p ${env_dir} \
    freecad occt=7.5 vtk=9 python=3.10 calculix blas=*=openblas gitpython \
    numpy matplotlib-base scipy sympy pandas six \
    pyyaml jinja2 opencamlib ifcopenshell \
    freecad.asm3 libredwg pycollada openglider \
    lxml xlutils olefile requests \
    blinker opencv qt.py nine docutils \
    --copy \
    -c freecad/label/dev \
    -c conda-forge \
    -y

mamba run -p ${env_dir} python ../scripts/get_freecad_version.py
read -r version_name < bundle_name.txt

echo -e "\################"
echo -e "version_name:  ${version_name}"
echo -e "################"

mamba list -p APP/FreeCAD.app/Contents/Resources > APP/FreeCAD.app/Contents/packages.txt
sed -i "1s/.*/\n\nLIST OF PACKAGES:/"  APP/FreeCAD.app/Contents/packages.txt

# add a bundle Identifier
/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier 'org.freecadteam.freecad'" "APP/FreeCAD.app/Contents/Info.plist"

# delete unnecessary stuff
rm -rf APP/FreeCAD.app/Contents/Resources/include
find APP/FreeCAD.app/Contents/Resources -name \*.a -delete
mv APP/FreeCAD.app/Contents/Resources/bin APP/FreeCAD.app/Contents/Resources/bin_tmp
mkdir APP/FreeCAD.app/Contents/Resources/bin
cp APP/FreeCAD.app/Contents/Resources/bin_tmp/freecad APP/FreeCAD.app/Contents/Resources/bin/
cp APP/FreeCAD.app/Contents/Resources/bin_tmp/freecadcmd APP/FreeCAD.app/Contents/Resources/bin
cp APP/FreeCAD.app/Contents/Resources/bin_tmp/ccx APP/FreeCAD.app/Contents/Resources/bin/
cp APP/FreeCAD.app/Contents/Resources/bin_tmp/python APP/FreeCAD.app/Contents/Resources/bin/
cp APP/FreeCAD.app/Contents/Resources/bin_tmp/pip APP/FreeCAD.app/Contents/Resources/bin/
cp APP/FreeCAD.app/Contents/Resources/bin_tmp/pyside2-rcc APP/FreeCAD.app/Contents/Resources/bin/
cp APP/FreeCAD.app/Contents/Resources/bin_tmp/assistant APP/FreeCAD.app/Contents/Resources/bin/
sed -i "" '1s|.*|#!/usr/bin/env python|' APP/FreeCAD.app/Contents/Resources/bin/pip
rm -rf APP/FreeCAD.app/Contents/Resources/bin_tmp

#copy qt.conf
cp qt.conf APP/FreeCAD.app/Contents/Resources/bin/
cp qt.conf APP/FreeCAD.app/Contents/Resources/libexec/

# add documentation
if [ ${ADD_DOCS} ]
then
    mkdir -p APP/FreeCAD.app/Contents/Resources/share/doc/FreeCAD
    cp ../../doc/* APP/FreeCAD.app/Contents/Resources/share/doc/FreeCAD
fi

# Remove __pycache__ folders and .pyc files
find . -path "*/__pycache__/*" -delete
find . -name "*.pyc" -type f -delete

# create the dmg
hdiutil create -volname "${version_name}" -srcfolder ./APP -ov -format UDZO "${version_name}.dmg"

# create hash
shasum -a 256 ${version_name}.dmg > ${version_name}.dmg-SHA256.txt
