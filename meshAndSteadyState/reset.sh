rm -rf log
rm -rf processor*
rm -rf backupNoLayer
rm -rf ./constant/polyMesh
rm -rf ./constant/fvOptions
rm -rf ./constant/extendedFeatureEdgeMesh
rm -rf ./constant/triSurface/*.eMesh
cp -r ./system/other/controlDict_initial ./system/controlDict
cp -r ./system/other/fvSchemes_initial ./system/fvSchemes
cp -r ./system/other/fvSolution_initial ./system/fvSolution
cp -r ./system/other/turbulenceProperties_initial ./constant/turbulenceProperties