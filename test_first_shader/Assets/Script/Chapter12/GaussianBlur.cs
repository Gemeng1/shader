using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GaussianBlur : PostEffectBase
{
    public Shader gaussianBlurShader;
    private Material gaussianBlurMaterial;

    public Material material
    {
        get
        {
            gaussianBlurMaterial = CheckShaderAndCreateMaterial(gaussianBlurShader, gaussianBlurMaterial);
            return gaussianBlurMaterial;
        }
    }

    [Range(0, 4)]
    public int iterations = 3;

    [Range(0.2f, 3.0f)]
    public float blurSpread = 0.6f;

    [Range(1, 8)]
    public int downSample = 2;

    //private void OnRenderImage(RenderTexture source, RenderTexture destination)
    //{
    //    if(material != null)
    //    {
    //        int rtW = source.width;
    //        int rtH = source.height;

    //        RenderTexture buffer = RenderTexture.GetTemporary(rtW, rtH, 0);
    //        Graphics.Blit(source, buffer, material, 0);
    //        Graphics.Blit(buffer,destination,material,1);

    //        RenderTexture.ReleaseTemporary(buffer);
    //    }
    //    else
    //    {
    //        Graphics.Blit(source, destination);
    //    }
    //}

    //这个处理相较上面的处理 减少了需要处理的像素个数 提高性能 适当降采样可以得到更好的效果
    //private void OnRenderImage(RenderTexture source, RenderTexture destination)
    //{
    //    if(material != null)
    //    {
    //        int rtW = source.width / downSample;//缩小屏幕分辨率
    //        int rtH = source.height / downSample;

    //        RenderTexture buffer = RenderTexture.GetTemporary(rtW, rtH, 0);//申请中间缓存 存储起一个pass（竖直方向的一维高斯核进行滤波） 的模糊结果
    //        buffer.filterMode = FilterMode.Bilinear;//设置临时渲染纹理的滤波模式  双线性

    //        Graphics.Blit(source, buffer, material, 0);//第一个pass 进行竖直方向的处理
    //        Graphics.Blit(buffer, destination, material, 1);//第二个pass 进行水平方向的处理

    //        RenderTexture.ReleaseTemporary(buffer);//释放临时渲染纹理的缓存
    //    }
    //    else
    //    {
    //        Graphics.Blit(source, destination);
    //    }
    //}

    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (material != null)
        {
            int rtW = source.width / downSample;
            int rtH = source.height / downSample;

            RenderTexture buffer0 = RenderTexture.GetTemporary(rtW, rtH, 0);//申请一块纹理缓存 buffer0

            buffer0.filterMode = FilterMode.Bilinear;

            Graphics.Blit(source, buffer0);//将source 缩放存储到buffer0
            for(int i = 0; i < iterations; i++)
            {
                material.SetFloat("_BlurSize", 1.0f + i * blurSpread);//对材质设置属性
                RenderTexture buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);//申请一块临时纹理缓存 buffer1

                Graphics.Blit(buffer0, buffer1, material, 0);//将buffer0 第一个pass 滤波处理 存入buffer1 中

                RenderTexture.ReleaseTemporary(buffer0);//释放buffer0 纹理缓存

                buffer0 = buffer1; //让buffer0 指向 buffer1
                buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);//buffer1 重新开辟一块缓存

                Graphics.Blit(buffer0, buffer1, material, 1);//将buffer0 第二个pass 滤波处理 存书buffer1 中 

                RenderTexture.ReleaseTemporary(buffer0);//释放buffer0  循环最前面buffer1 开辟的缓存

                buffer0 = buffer1;//buffer0 再次指向新的 buffer 缓存
            }

            Graphics.Blit(buffer0, destination);//将buffer0 存储到最终的图像
         
            RenderTexture.ReleaseTemporary(buffer0);//释放纹理缓存
        }
        else
        {
            Graphics.Blit(source, destination);
        }
    }
}
