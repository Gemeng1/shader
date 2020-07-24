using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class FogWithNoise : PostEffectBase
{
    public Shader fogShader;
    private Material fogMaterial = null;
    Material material
    {
        get
        {
            fogMaterial = CheckShaderAndCreateMaterial(fogShader, fogMaterial);
            return fogMaterial;
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

    private Transform myCameraTransform;
    Transform cameraTranform
    {
        get
        {
            if(myCameraTransform == null)
            {
                myCameraTransform = camera.transform;
            }
            return myCameraTransform;
        }
    }

    private void OnEnable()
    {
        camera.depthTextureMode |= DepthTextureMode.Depth;
    }

    [Range(1.0f, 3.0f)]
    public float fogDensity = 1.0f;

    public Color fogColor = Color.white;

    public float fogStart = 0.0f;

    public float fogEnd = 2.0f;

    public Texture noiseTexture;

    [Range(-0.5f, 0.5f)]
    public float fogXSpeed = 1.0f;

    [Range(-0.5f, 0.5f)]
    public float fogYSpeed = 1.0f;

    [Range(0.0f, 3.0f)]
    public float noiseAmount = 1.0f;

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if(material != null)
        {
            Matrix4x4 matrix = Matrix4x4.identity;

            float fov = camera.fieldOfView;
            float near = camera.nearClipPlane;
            float aspect = camera.aspect;

            float height = near * Mathf.Tan(fov * 0.5f * Mathf.Rad2Deg);


            Vector3 toTop = cameraTranform.up * height;
            Vector3 toRight = cameraTranform.right * height * aspect;

            Vector3 topLeft = cameraTranform.forward * near + toTop - toRight;
            float scale = topLeft.magnitude / near;

            topLeft.Normalize();
            topLeft *= scale;

            Vector3 topRight = cameraTranform.forward * near + toTop + toRight;
            topRight.Normalize();
            topRight *= scale;

            Vector3 bottomLeft = cameraTranform.forward * near - toTop - toRight;
            bottomLeft.Normalize();
            bottomLeft *= scale;

            Vector3 bottomRight = cameraTranform.forward * near - toTop + toRight;
            bottomRight.Normalize();
            bottomRight *= scale;

            matrix.SetRow(0, bottomLeft);//
            matrix.SetRow(1, bottomRight);
            matrix.SetRow(2, topRight);
            matrix.SetRow(3, topLeft);

            material.SetMatrix("_RayMatrix", matrix);
            material.SetFloat("_FogDensity", fogDensity);
            material.SetColor("_FogColor", fogColor);
            material.SetFloat("_FogStart", fogStart);
            material.SetFloat("_FogEnd", fogEnd);
            material.SetTexture("_NoiseTexture", noiseTexture);
            material.SetFloat("_FogXSpeed", fogXSpeed);
            material.SetFloat("_FogYSpeed", fogYSpeed);
            material.SetFloat("_NoiseAmount", noiseAmount);

            Graphics.Blit(source, destination, material);
        }
        else
        {
            Graphics.Blit(source, destination);
        }
    }

}
