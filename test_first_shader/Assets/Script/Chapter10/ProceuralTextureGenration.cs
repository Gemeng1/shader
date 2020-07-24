using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]//编辑器下模式运行
public class ProceuralTextureGenration : MonoBehaviour
{
    public Material material = null;//声明一个材质

    #region Material properties
    [SerializeField, SetProperty("textureWidth")]
    private int m_textureWidth = 512;
    public int textureWidth//纹理大小
    {
        get
        {
            return m_textureWidth;
        }

        set
        {
            m_textureWidth = value;
            _UpdateMaterial();
        }
    }

    [SerializeField, SetProperty("backgroundColor")]//纹理背景颜色
    private Color m_backgroundColor = Color.white;
    public Color backgroundColor
    {
        get
        {
            return m_backgroundColor;
        }

        set
        {
            m_backgroundColor = value;
            _UpdateMaterial();
        }
    }


    [SerializeField, SetProperty("circleColor")]//圆点颜色
    private Color m_circleColor = Color.yellow;
    public Color circleColor
    {
        get
        {
            return m_circleColor;
        }

        set
        {
            m_circleColor = value;
            _UpdateMaterial();
        }
    }


    [SerializeField, SetProperty("blueFactor")]//模糊因子
    private float m_blueFactor = 2.0f;
    public float blueFactor
    {
        get
        {
            return m_blueFactor;
        }

        set
        {
            m_blueFactor = value;
            _UpdateMaterial();
        }
    }

    #endregion

    private Texture2D m_generationTexture = null;

    private void Start()
    {
        if(material == null)
        {
            Renderer renderer = gameObject.GetComponent<Renderer>();
            if(renderer == null)
            {
                Debug.LogWarning("Cannot find a renderer");
                return;
            }

            material = renderer.sharedMaterial;
        }
        _UpdateMaterial();
    }

    private void _UpdateMaterial()
    {
        if(material != null)
        {
            m_generationTexture = _GenerationProceduralTexture();
            material.SetTexture("_MainTex",m_generationTexture);
        }
    }

    private Color _MixColor(Color color1,Color color2,float mixFloat)
    {
        Color mixColor = Color.white;
        mixColor.r = Mathf.Lerp(color1.r, color2.r, mixFloat);
        mixColor.g = Mathf.Lerp(color1.g, color2.g, mixFloat);
        mixColor.b = Mathf.Lerp(color1.b, color2.b, mixFloat);
        mixColor.a = Mathf.Lerp(color1.a, color2.a, mixFloat);
        return mixColor;
    }

    private Texture2D _GenerationProceduralTexture()
    {
        Texture2D proceduralTexture = new Texture2D(textureWidth, textureWidth);

        float circleInterval = textureWidth / 4.0f;

        float redius = textureWidth / 10.0f;

        float edgeBlur = 1.0f / blueFactor;

        for(int w = 0; w < textureWidth; w++)
        {
            for(int h = 0; h < textureWidth; h++)
            {
                Color pixel = backgroundColor;

                for(int i = 0; i < 3; i++)
                {
                    for(int j = 0; j < 3; j++)
                    {
                        Vector2 circleCenter = new Vector2(circleInterval * (i + 1), circleInterval * (j + 1));

                        float dist = Vector2.Distance(new Vector2(w, h), circleCenter) - redius;

                        Color color = _MixColor(circleColor, new Color(pixel.r, pixel.g, pixel.b, 0.0f), Mathf.SmoothStep(0.0f, 1.0f, edgeBlur * dist));

                        pixel = _MixColor(pixel, color, color.a);
                    }
                }
                proceduralTexture.SetPixel(w, h, pixel);
            }
         
        }
        proceduralTexture.Apply();
        return proceduralTexture;
    }

}
