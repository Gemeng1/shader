using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class DepthTexture : PostEffectBase
{
    public Shader depthTextureShader;
    private Material depthTextureMaterial = null;
    Material material
    {
        get
        {
            depthTextureMaterial = CheckShaderAndCreateMaterial(depthTextureShader, depthTextureMaterial);
            return depthTextureMaterial;
        }
    }
    private Camera myCamera;
    public Camera camera
    {
        get
        {
            if(myCamera == null)
            {
                myCamera = GetComponent<Camera>();
            }
            return myCamera;
        }
    }
    private void OnEnable()
    {
        camera.depthTextureMode |= DepthTextureMode.Depth;
    }

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if(material != null)
        {
            Graphics.Blit(source, destination, material);
        }
        else
        {
            Graphics.Blit(source, destination);
        }
    }
}
