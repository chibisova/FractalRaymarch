using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[RequireComponent(typeof(Camera))]
[ExecuteInEditMode]
public class RaymarchCamera : SceneViewFilter
{
    [SerializeField]
    private Shader _shader;

    public Material _raymarchMaterial
    {
        get
        {
            if (!_raymarchMat && _shader)
            {
                _raymarchMat = new Material(_shader);
                _raymarchMat.hideFlags = HideFlags.HideAndDontSave;
            }
            return _raymarchMat;
        }
    }

    private Material _raymarchMat;

    public Camera _camera
    {
        get
        {
            if (!_cam)
            {
                _cam = GetComponent<Camera>();
            }

            return _cam;
        }
    }

    private Camera _cam;
    private float _forceFieldRad;

    public Transform _directionalLight;
    public Transform _player;
    
    public float _precision;
    [Header("Visual Settings")]
    public bool _useNormal;
    public bool _useShadow;
    [Range(0, 1)]
    public float _lightIntensity;
    [Range(0, 1)]
    public float _shadowIntensity;
    [Range(0, 1)]
    public float _aoIntensity;
    public Color _mainColor;
    public Color _secColor;
    public Color _skyColor;
    public Color _forceFieldColor;
    
    public float _maxDistance;
    [Header("Choose The Shape")]
    public bool _drawMergerSponge;
    public bool _drawMergerCylinder;
    public bool _drawMergerPyramid;
    public bool _drawNegativeSphere;
    public bool _drawSierpinskiTriangle;
    public bool _drawMandelbulb;
    public bool _drawTowerIFS;
    public bool _drawAbstractFractal;
    public bool _drawHartverdrahtet;
    public bool _drawPseudoKleinia;
    public bool _drawPseudoKnightyan;
    public bool _drawTree;
    
    [Header ("Fractal Transform")]
    public int _iterations;
    public float _power;
    public float _scaleFactor;
    public Vector3 _modOffsetPos;
    public Vector3 _iterationOffsetPos;
    public Vector3 _iterationOffsetRot;
    
    [Header("Transform Settings")]
    public Vector3 _globalPosition;
    public Vector3 _GlobalRotation;  
    public float _GlobalScale;
    public float _smoothRadius;
    public float _innerSphereRad;

    
    [HideInInspector]
    public Matrix4x4 _iterationTransform;
    [HideInInspector]
    public Matrix4x4 _sectionTransform;
    [HideInInspector]
    public Matrix4x4 _globalTransform;
    
    public int _functionNum;
    
    /*
    [Header("Modulor Settings")]
    public bool _useModulor;
    public Vector3 _modInterval;*/
    private void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (_drawMergerSponge == true || _drawMergerCylinder == true || _drawMergerPyramid == true || _drawNegativeSphere == true)
        {
            if (_drawMergerSponge) _functionNum = 1;
            if (_drawMergerCylinder) _functionNum = 2;
            if (_drawMergerPyramid) _functionNum = 3;
            if (_drawNegativeSphere) _functionNum = 4;
            
            
            // Send the matrix to our shader
            _raymarchMaterial.SetMatrix("_iterationTransform", _iterationTransform.inverse);
            //_raymarchMaterial.SetVector("_modInterval", _modInterval);
            _raymarchMaterial.SetVector("_modOffsetPos", _modOffsetPos);
            _raymarchMaterial.SetFloat("_scaleFactor", _scaleFactor);
            _raymarchMaterial.SetFloat("_innerSphereRad", _innerSphereRad);
            _raymarchMaterial.SetFloat("_smoothRadius", _smoothRadius);
        }
        else if (_drawSierpinskiTriangle == true)
        {
            _functionNum = 5;
            _raymarchMaterial.SetFloat("_scaleFactor", _scaleFactor);
        }
        else if (_drawMandelbulb == true)
        {
            _functionNum = 6;
            _raymarchMaterial.SetFloat("_smoothRadius", _smoothRadius);
            
        }
        else if (_drawTowerIFS == true)
        {
            _functionNum = 7;
        }
        else if (_drawAbstractFractal == true)
        {
            _functionNum = 8;
        }
        else if (_drawHartverdrahtet == true)
        {
            _functionNum = 9;
        }
        else if (_drawPseudoKleinia == true)
        {
            _functionNum = 10;
        }
        else if (_drawPseudoKnightyan == true)
        {
            _functionNum = 11;
        }
        
        
        // Send the matrix to our shader
        _raymarchMaterial.SetMatrix("_globalTransform", _globalTransform.inverse);
        _raymarchMaterial.SetVector("_globalPosition", _globalPosition);
        
        if (_useNormal) _raymarchMaterial.SetInt("_useNormal", 1);
        else _raymarchMaterial.SetInt("_useNormal", 0);

        if (_useShadow) _raymarchMaterial.SetInt("_useShadow", 1);
        else _raymarchMaterial.SetInt("_useShadow", 0);
        
        if (!_raymarchMaterial)
        {
            Graphics.Blit(source, destination);
            return;
        }
        _forceFieldRad = _player.gameObject.GetComponent<SphereCollider>().radius;
        
        _raymarchMaterial.SetVector("_LightDir", _directionalLight ? _directionalLight.forward : Vector3.down);
        _raymarchMaterial.SetVector("_player", _player ? _player.position : Vector3.zero);
        _raymarchMaterial.SetMatrix("_CamFrustum", CamFrustum(_camera));
        _raymarchMaterial.SetMatrix("_CamToWorld", _camera.cameraToWorldMatrix);
        _raymarchMaterial.SetFloat("_maxDistance", Camera.main.farClipPlane);
        _raymarchMaterial.SetFloat("_precision", _precision);
        _raymarchMaterial.SetFloat("_lightIntensity", _lightIntensity);
        _raymarchMaterial.SetFloat("_shadowIntensity", _shadowIntensity);
        _raymarchMaterial.SetFloat("_aoIntensity", _aoIntensity);
        _raymarchMaterial.SetInt("_iterations", _iterations);
        _raymarchMaterial.SetFloat("_power", _power);

        //_raymarchMaterial.SetVector("_modInterval", _modInterval);
        _raymarchMaterial.SetColor("_mainColor", _mainColor);
        _raymarchMaterial.SetColor("_secColor", _secColor);
        _raymarchMaterial.SetColor("_skyColor", _skyColor);
        _raymarchMaterial.SetColor("_forceFieldColor", _forceFieldColor);
        _raymarchMaterial.SetFloat("_GlobalScale", _GlobalScale);
        
        _raymarchMaterial.SetInt("_functionNum", _functionNum);
        RenderTexture.active = destination;
        _raymarchMaterial.SetTexture("_MainTex", source);
        GL.PushMatrix();
        GL.LoadOrtho();
        _raymarchMaterial.SetPass(0);
        GL.Begin(GL.QUADS);
        
        //BL
        GL.MultiTexCoord2(0, 0.0f, 0.0f);
        GL.Vertex3(0.0f, 0.0f, 3.0f);
        //BR
        GL.MultiTexCoord2(0, 1.0f, 0.0f);
        GL.Vertex3(1.0f, 0.0f, 2.0f);
        //TR
        GL.MultiTexCoord2(0, 1.0f, 1.0f);
        GL.Vertex3(1.0f, 1.0f, 1.0f);
        //TL
        GL.MultiTexCoord2(0, 0.0f, 1.0f);
        GL.Vertex3(0.0f, 1.0f, 0.0f);

        GL.End();
        GL.PopMatrix();
    }

    private Matrix4x4 CamFrustum(Camera cam)
    {
        Matrix4x4 frustum = Matrix4x4.identity;
        float fov = Mathf.Tan((cam.fieldOfView * 0.5f) * Mathf.Deg2Rad);

        Vector3 goUp = Vector3.up * fov;
        Vector3 goRight = Vector3.right * fov * cam.aspect;

        Vector3 TL = (-Vector3.forward - goRight + goUp);
        Vector3 TR = (-Vector3.forward + goRight + goUp);
        Vector3 BR = (-Vector3.forward + goRight - goUp);
        Vector3 BL = (-Vector3.forward - goRight - goUp);

        frustum.SetRow(0, TL);
        frustum.SetRow(1, TR);
        frustum.SetRow(2, BR);
        frustum.SetRow(3, BL);
        
        return frustum;

    }
}
