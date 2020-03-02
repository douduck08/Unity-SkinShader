using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEngine;
using UnityEditor;

public static class PrecomputeTranslucency {

    const int WIDTH = 512;
    const int HEIGHT = 4;

    // http://iryoku.com/translucency/
    static Vector3 T (float s) {
        return new Vector3 (0.233f, 0.455f, 0.649f) * Mathf.Exp (-s * s / 0.0064f) +
            new Vector3 (0.100f, 0.336f, 0.344f) * Mathf.Exp (-s * s / 0.0484f) +
            new Vector3 (0.118f, 0.198f, 0.000f) * Mathf.Exp (-s * s / 0.187f) +
            new Vector3 (0.113f, 0.007f, 0.007f) * Mathf.Exp (-s * s / 0.567f) +
            new Vector3 (0.358f, 0.004f, 0.000f) * Mathf.Exp (-s * s / 1.99f) +
            new Vector3 (0.078f, 0.000f, 0.000f) * Mathf.Exp (-s * s / 7.41f);
    }

    [MenuItem ("Tools/Create Precompute Translucency Texture")]
    static void CreatePrecomputeTranslucencyTexture () {
        string path = EditorUtility.SaveFilePanelInProject ("Create Precompute Translucency Texture", "PrecomputeTranslucency", "jpg", "");
        if (string.IsNullOrEmpty (path)) {
            return;
        }

        var output = new Texture2D (WIDTH, HEIGHT, TextureFormat.RGB24, false);
        for (int x = 0; x < WIDTH; x++) {
            var s = x * (1f / (WIDTH - 1));
            var trans = T (s);
            var color = new Color (trans.x, trans.y, trans.z);
            for (int y = 0; y < HEIGHT; y++) {
                output.SetPixel (x, y, color);
            }
        }
        output.Apply ();

        var bytes = ImageConversion.EncodeToJPG (output, 100);
        File.WriteAllBytes (path, bytes);

        AssetDatabase.Refresh ();
    }

}