using UnityEngine;
using UnityEngine.Rendering;
using UnityEditor;
using UnityEditor.SceneManagement;
using System.Linq;

[CanEditMultipleObjects]
public class MatInspector : ShaderGUI
{
    private Material targetMat;

    private GUIStyle style, bigLabelStyle, smallLabelStyle;
    private const int bigFontSize = 16, smallFontSize = 11;
    private string[] oldKeyWords;
    private int effectCount = 1;
    private Material originalMaterialCopy;
    private MaterialEditor matEditor;
    private MaterialProperty[] matProperties;

    public override void OnGUI(MaterialEditor materialEditor, MaterialProperty[] properties)
    {
        matEditor = materialEditor;
        matProperties = properties;
        targetMat = materialEditor.target as Material;
        effectCount = 1;
        oldKeyWords = targetMat.shaderKeywords;
        style = new GUIStyle(EditorStyles.helpBox);
        style.margin = new RectOffset(0, 0, 0, 0);
        bigLabelStyle = new GUIStyle(EditorStyles.boldLabel);
        bigLabelStyle.fontSize = bigFontSize;
        smallLabelStyle = new GUIStyle(EditorStyles.boldLabel);
        smallLabelStyle.fontSize = smallFontSize;

        GUILayout.Label("General Properties", bigLabelStyle);
        DrawProperty(0);
        DrawProperty(1);

        //Not needed since Unity batches sprites on its own
        //EditorGUILayout.Separator();
        //materialEditor.EnableInstancingField();
        //Debug.Log(materialEditor.IsInstancingEnabled() + "  " + Application.isBatchMode);

        EditorGUILayout.Separator();

        DrawLine(Color.grey, 1, 3);
        GUILayout.Label("Color Effects", bigLabelStyle);

        GenericEffect("Rim Lighting", "RIM_ON", 2, 5);
        GenericEffect("Hue Shift", "HSV_ON", 6, 8);

        EditorGUILayout.Separator();

        DrawLine(Color.grey, 1, 3);
        GenericEffect("Unity Fog", "FOG_ON", -1, -1, false);
    }
    private void GenericEffect(string inspector, string keyword, int first, int last, bool effectCounter = true, string preMessage = null, int[] extraProperties = null)
    {
        bool toggle = oldKeyWords.Contains(keyword);
        bool ini = toggle;

        GUIContent effectNameLabel = new GUIContent();
        effectNameLabel.tooltip = keyword + " (C#)";
        if (effectCounter)
        {
            effectNameLabel.text = effectCount + "." + inspector;
            toggle = EditorGUILayout.BeginToggleGroup(effectNameLabel, toggle);
            effectCount++;
        }
        else
        {
            effectNameLabel.text = inspector;
            toggle = EditorGUILayout.BeginToggleGroup(effectNameLabel, toggle);
        }

        if (ini != toggle && !Application.isPlaying) EditorSceneManager.MarkSceneDirty(EditorSceneManager.GetActiveScene());
        if (toggle)
        {
            targetMat.EnableKeyword(keyword);
            if (first > 0)
            {
                EditorGUILayout.BeginVertical(style);
                {
                    if (preMessage != null) GUILayout.Label(preMessage, smallLabelStyle);
                    for (int i = first; i <= last; i++) DrawProperty(i);
                    if (extraProperties != null) foreach (int i in extraProperties) DrawProperty(i);
                }
                EditorGUILayout.EndVertical();
            }
        }
        else targetMat.DisableKeyword(keyword);
        EditorGUILayout.EndToggleGroup();
    }
    private void DrawProperty(int index, bool noReset = false)
    {
        MaterialProperty targetProperty = matProperties[index];

        EditorGUILayout.BeginHorizontal();
        {
            GUIContent propertyLabel = new GUIContent();
            propertyLabel.text = targetProperty.displayName;
            propertyLabel.tooltip = targetProperty.name + " (C#)";

            matEditor.ShaderProperty(targetProperty, propertyLabel);

            if (!noReset)
            {
                GUIContent resetButtonLabel = new GUIContent();
                resetButtonLabel.text = "R";
                resetButtonLabel.tooltip = "Resets to default value";
                if (GUILayout.Button(resetButtonLabel, GUILayout.Width(20))) ResetProperty(targetProperty);
            }
        }
        EditorGUILayout.EndHorizontal();
    }

    private void ResetProperty(MaterialProperty targetProperty)
    {
        if (originalMaterialCopy == null) originalMaterialCopy = new Material(targetMat.shader);
        if (targetProperty.type == MaterialProperty.PropType.Float || targetProperty.type == MaterialProperty.PropType.Range)
        {
            targetProperty.floatValue = originalMaterialCopy.GetFloat(targetProperty.name);
        }
        else if (targetProperty.type == MaterialProperty.PropType.Vector)
        {
            targetProperty.vectorValue = originalMaterialCopy.GetVector(targetProperty.name);
        }
        else if (targetProperty.type == MaterialProperty.PropType.Color)
        {
            targetProperty.colorValue = originalMaterialCopy.GetColor(targetProperty.name);
        }
        else if (targetProperty.type == MaterialProperty.PropType.Texture)
        {
            targetProperty.textureValue = originalMaterialCopy.GetTexture(targetProperty.name);
        }
    }

    private void DrawLine(Color color, int thickness = 2, int padding = 10)
    {
        Rect r = EditorGUILayout.GetControlRect(GUILayout.Height(padding + thickness));
        r.height = thickness;
        r.y += (padding / 2);
        r.x -= 2;
        r.width += 6;
        EditorGUI.DrawRect(r, color);
    }
}
