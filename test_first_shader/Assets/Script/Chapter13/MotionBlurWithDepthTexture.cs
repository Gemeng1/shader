using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MotionBlurWithDepthTexture : PostEffectBase
{
    public Shader motionBlurShader;
    private Material motionBlurMaterial = null;

    Material material
    {
        get
        {
            motionBlurMaterial = CheckShaderAndCreateMaterial(motionBlurShader, motionBlurMaterial);
            return motionBlurMaterial;
        }
    }

    private Camera myCamera;

    Camera camera
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

    private Matrix4x4 oldMatrix;
    [Range(0.0f, 1.0f)]
    public float BlurSize;

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if(material != null)
        {
            material.SetMatrix("_OldMatrix", oldMatrix);
            Matrix4x4 curMatrix = camera.projectionMatrix * camera.worldToCameraMatrix;
            Matrix4x4 curMatrixInverse = curMatrix.inverse;
            material.SetMatrix("_CurMatrixInverse", curMatrixInverse);
            oldMatrix = curMatrix;
            Graphics.Blit(source, destination, material);
        }
        else
        {
            Graphics.Blit(source, destination);
        }
    }

}
