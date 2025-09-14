using UnityEngine;
using UnityEditor;

[CustomEditor(typeof(ComputeGrassManager))]
public class ComputeGrassManagerEditor : Editor
{
    public override void OnInspectorGUI()
    {
        DrawDefaultInspector();
        
        ComputeGrassManager grassManager = (ComputeGrassManager)target;
        
        GUILayout.Space(10);
        
        if (GUILayout.Button("Generate Grass"))
        {
            grassManager.GenerateGrass();
        }
        
        if (GUILayout.Button("Clear Grass"))
        {
            grassManager.ClearGrass();
        }
    }
}