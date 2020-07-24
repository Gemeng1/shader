using UnityEngine;
using System.Collections;

[ExecuteInEditMode]
[RequireComponent(typeof(Camera))]
public class PostEffectBase : MonoBehaviour
{
    [System.Obsolete]
    protected void CheckResources()
	{
		bool isSupport = CheckSupport();
		if (isSupport == false)
		{
            NotSupported();
		}

	}

    [System.Obsolete]
    protected bool CheckSupport()
	{
		if (SystemInfo.supportsImageEffects == false || SystemInfo.supportsRenderTextures == false)
		{
			Debug.LogWarning("This platform does not support image effects or render textures.");
			return false;
		}
        return true;

	}

	protected void NotSupported()
	{
		enabled = false;
	}

    // Start is called before the first frame update
    [System.Obsolete]
    void Start()
    {
        CheckResources();
    }

    protected Material CheckShaderAndCreateMaterial(Shader shader, Material material)
	{
		if (shader == null)
			return null;
        if(shader.isSupported && material&&material.shader==shader)
		{
			return material;
		}

		if (!shader.isSupported)
		{
			return null;
		}
		else
		{
			material = new Material(shader);
			material.hideFlags = HideFlags.DontSave;
			if (material)
				return material;
		}
		return null;
	}
}
