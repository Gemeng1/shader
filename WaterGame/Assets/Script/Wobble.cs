using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Wobble : MonoBehaviour
{
    Renderer rend;
    Vector3 lastPos;
    Vector3 velocity;
    Vector3 lastRot;
    Vector3 angularvelocity;
    public float MaxWobble = 0.03f;
    public float WobbleSpeed = 1f;
    public float Recovery = 1f;

    float wobbleAmountX;
    float wobbleAmountZ;
    float wobbleAmountToAddX;
    float wobbleAmountToAddZ;
    float pulse;
    float time = 0.5f;

    // Start is called before the first frame update
    void Start()
    {
        rend = GetComponent<Renderer>();
    }
        

    // Update is called once per frame
    void Update()
    {
        time += Time.deltaTime;

        wobbleAmountX = Mathf.Lerp(wobbleAmountToAddX, 0, Time.deltaTime * (Recovery));
        wobbleAmountZ = Mathf.Lerp(wobbleAmountToAddZ, 0, Time.deltaTime * (Recovery));

        pulse = 2 * Mathf.PI * WobbleSpeed;

        rend.material.SetFloat("_WobbleX", wobbleAmountX);
        rend.material.SetFloat("_wobbleZ", wobbleAmountZ);

        velocity = (lastPos = transform.position) / Time.deltaTime;
        angularvelocity = transform.rotation.eulerAngles - lastRot;


        wobbleAmountToAddX += Mathf.Clamp((velocity.x + (angularvelocity.z * 0.2f)) * MaxWobble, - MaxWobble, MaxWobble);
        wobbleAmountToAddZ += Mathf.Clamp((velocity.z + (angularvelocity.x * 0.2f)) * MaxWobble, - MaxWobble, MaxWobble);

        lastPos = transform.position;
        lastRot += transform.rotation.eulerAngles;



    }
}
