#################################################################
# Non è consigliabile runnare l'intero script in una volta sola #
#################################################################

cd meshAndSteadyState
mkdir log
mkdir backupNoLayer
cp -r ./0.orig ./0

### MESHING
blockMesh > log/blockMesh
surfaceFeatureExtract  > log/surfaceFeatureExtract

decomposePar -force -latestTime > log/decomposeParBlock
# NoLayer
mpirun -np 16 snappyHexMesh -overwrite -parallel > log/snappyHexMesh
cp -r ./processor* ./backupNoLayer
# Layer
mpirun -np 16 snappyHexMesh -overwrite -dict system/layerDict -parallel > log/snappyHexMeshLayer
mpirun -np 16 checkMesh -allTopology -allGeometry -parallel > log/checkMesh

# Cambio delle BC (creazione cyclic BC)
mpirun -np 16 createPatch -parallel -overwrite > log/createPatch
reconstructParMesh -constant -fullMatch -mergeTol 1e-10 > log/reconstructParMesh

changeDictionary > log/changeDictionary

### STEADYSTATE
decomposePar -force -latestTime > log/decomposeParBlock
mpirun -np 16 renumberMesh -overwrite -latestTime -parallel > log/renumberMesh
# Prima parte. No poroso, no fan. Metodi conservativi
mpirun -np 16 potentialFoam -parallel > log/potentialFoam
mpirun -np 16 simpleFoam -parallel > log/simpleFoam

# Seconda parte. Poroso, no fan. Metodi un po' meno conservativi
cp -r ./system/other/controlDict_intermediate ./system/controlDict
cp -r ./system/other/fvSchemes_intermediate ./system/fvSchemes
cp -r ./system/other/fvSolution_intermediate ./system/fvSolution
cp -r ./system/other/fvOptions ./constant/fvOptions
mpirun -np 16 simpleFoam -parallel > log/simpleFoamPorous

# Terza parte. Poroso, fan (farlocchi, utilizzando fixedJump). Metodi conservativi
mpirun -np 16 changeDictionary -dict system/changeDictionaryDict2 -parallel -latestTime > log/changeDictionary2
cp -r ./system/other/controlDict_intermediate_fan ./system/controlDict
cp -r ./system/other/fvSchemes_intermediate_fan ./system/fvSchemes
cp -r ./system/other/fvSolution_intermediate_fan ./system/fvSolution
mpirun -np 16 simpleFoam -parallel > log/simpleFoamFan

# Quarta parte. Poroso, fan (veri). Metodi meno conservativi e più precisi
mpirun -np 16 changeDictionary -dict system/changeDictionaryDict3 -parallel -latestTime > log/changeDictionary3
rm -rf ./processor*/650/phi
cp -r ./system/other/controlDict_final ./system/controlDict
cp -r ./system/other/fvSchemes_final ./system/fvSchemes
cp -r ./system/other/fvSolution_final ./system/fvSolution
cp -r ./system/other/turbulenceProperties_final ./constant/turbulenceProperties
mpirun -np 16 simpleFoam -parallel > log/simpleFoamFinal

reconstructPar -latestTime > log/reconstructPar

### TRANSIENT
# Copia dalla simulazione steady
cp -r ./1300 $FOAM_RUN/transient/0
cd $FOAM_RUN/transient
rm -rf ./0/phi
rm -rf ./0/uniform
mkdir log

# Risoluzione
decomposePar -force -latestTime > log/decomposeParBlock
mpirun -np 16 pimpleFoam -parallel > log/pimpleFoam

reconstructPar -latestTime > log/reconstructPar
