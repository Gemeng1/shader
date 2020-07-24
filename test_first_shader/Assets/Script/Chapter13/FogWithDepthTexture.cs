using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class FogWithDepthTexture : PostEffectBase
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
    Transform cameraTransform
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

    [Range(0.0f, 3.0f)]
    public float fogdensity = 1.0f;

    public Color fogColor = Color.white;

    public float fogStart = 0.0f;
    public float fogEnd = 2.0f;

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if(material != null)
        {
            Matrix4x4 matrix = Matrix4x4.identity;//默认初始化一个4x4矩阵

            float fov = camera.fieldOfView;//竖直方向视角
            float near = camera.nearClipPlane;//距离近面剪裁平面的距离
            float aspect = camera.aspect;//宽高比

            float Height = near * Mathf.Tan(fov *0.5f * Mathf.Deg2Rad);//算出高度 Mathf.Deg2Rad 角度转弧度

            Vector3 toRight = cameraTransform.right * Height * aspect;//算出近面剪裁平面 半宽
            Vector3 toTop = cameraTransform.up * Height;//近面剪裁平面半高

            Vector3 topLeft = cameraTransform.forward * near + toTop - toRight;//算出近面剪裁平面左上的点
            float scale = topLeft.magnitude / near;//点的模/近面剪裁距离

            topLeft.Normalize();
            topLeft *= scale;

            Vector3 topRight = cameraTransform.forward * near + toTop + toRight;

            topRight.Normalize();
            topRight *= scale;

            Vector3 bottomLeft = cameraTransform.forward * near - toTop - toRight;
            bottomLeft.Normalize();
            bottomLeft *= scale;

            Vector3 bottomRight = cameraTransform.forward * near - toTop + toRight;
            bottomRight.Normalize();
            bottomRight *= scale;

            matrix.SetRow(0, bottomLeft);
            matrix.SetRow(1, bottomRight);
            matrix.SetRow(2, topRight);
            matrix.SetRow(3, topLeft);

            material.SetMatrix("_RayMatrix", matrix);
            material.SetFloat("_FogDensity", fogdensity);
            material.SetColor("_FogColor", fogColor);
            material.SetFloat("_FogStart", fogStart);
            material.SetFloat("_FogEnd", fogEnd);


            Graphics.Blit(source, destination, material);

        }
        else
        {
            Graphics.Blit(source, destination);
        }
    }

}
