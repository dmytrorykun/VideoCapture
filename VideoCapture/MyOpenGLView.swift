//
//  MyOpenGLView.swift
//  VideoCapture
//
//  Created by user on 12/4/17.
//  Copyright © 2017 peoplecanfly. All rights reserved.
//

import Cocoa
import OpenGL
import GLKit
import AVFoundation

struct Vector4
{
    var x = 0.0 as GLfloat
    var y = 0.0 as GLfloat
    
    var u = 0.0 as GLfloat
    var v = 0.0 as GLfloat
}

class MyNSOpenGLView: NSOpenGLView, AVCaptureVideoDataOutputSampleBufferDelegate
{
    private var vertexArrayId : GLuint = 0
    private var positionAttribute : GLuint = 0
    private var textureCoordinatesAttribute : GLuint = 0
    private var shaderProgram : ShaderProgram?
    private var videoTextureCache : CVOpenGLTextureCache?
    
    override func awakeFromNib()
    {
        setupContext()
        loadShaders()
        setupVertexBuffer()
        
//        perform(#selector(MyNSOpenGLView.render), with: nil, afterDelay: 1);
    }
    
    override func reshape()
    {
        glViewport(0, 0, GLsizei(self.frame.size.width), GLsizei(self.frame.size.height))
    }
    
    func setupContext()
    {
        let attr = [
            NSOpenGLPixelFormatAttribute(NSOpenGLPFAOpenGLProfile),
            NSOpenGLPixelFormatAttribute(NSOpenGLProfileVersion3_2Core),
            NSOpenGLPixelFormatAttribute(NSOpenGLPFAColorSize), 24,
            NSOpenGLPixelFormatAttribute(NSOpenGLPFAAlphaSize), 8,
            NSOpenGLPixelFormatAttribute(NSOpenGLPFADoubleBuffer),
            NSOpenGLPixelFormatAttribute(NSOpenGLPFANoRecovery),
            NSOpenGLPixelFormatAttribute(NSOpenGLPFAAccelerated),
            0
        ]
        
        let format = NSOpenGLPixelFormat(attributes: attr)
        let context = NSOpenGLContext(format: format!, share: nil)
        
        let err = CVOpenGLTextureCacheCreate(kCFAllocatorDefault,
                                             nil,
                                             (context?.cglContextObj)!,
                                             (format?.cglPixelFormatObj)!,
                                             nil,
                                             &videoTextureCache)
        if err != kCVReturnSuccess {
            //error
        }
        
        self.openGLContext = context
        self.openGLContext!.makeCurrentContext()
    }
    
    func setupVertexBuffer()
    {
        let vertices = [
            Vector4(x: -1.0, y: -1.0, u: 0.0, v: 1.0 ),
            Vector4(x: -1.0, y:  1.0, u: 0.0, v: 0.0 ),
            Vector4(x:  1.0, y:  1.0, u: 1.0, v: 0.0 ),
            Vector4(x:  1.0, y: -1.0, u: 1.0, v: 1.0 )
        ]
        
        glGenVertexArrays(1, &vertexArrayId)
        glBindVertexArray(vertexArrayId)
        
        var bufferIds = [GLuint](repeating: 0, count: 1)
        glGenBuffers(1, &bufferIds)
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), bufferIds[0])
        
        let size = MemoryLayout<Vector4>.size
        
        glBufferData(GLenum(GL_ARRAY_BUFFER), (size * vertices.count), vertices, GLenum(GL_STATIC_DRAW))
        
        glEnableVertexAttribArray(GLuint(positionAttribute))
        glVertexAttribPointer(GLuint(positionAttribute), 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(size), nil)
        
        glEnableVertexAttribArray(GLuint(textureCoordinatesAttribute))
        glVertexAttribPointer(GLuint(textureCoordinatesAttribute), 2, GLenum(GL_FLOAT), GLboolean(GL_FALSE), GLsizei(size), UnsafeRawPointer(bitPattern:MemoryLayout<GLfloat>.size*2))
    }
    
    func render()
    {
        self.openGLContext!.makeCurrentContext()
        
        glClearColor(0.0, 0.5, 0.0, 1.0);
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT));
        shaderProgram!.use()
        
        glBindVertexArray(vertexArrayId)
        glDrawArrays(GLenum(GL_TRIANGLE_FAN), 0, GLint(4))
        
        self.openGLContext!.flushBuffer()
    }
    
    //MARK: - Shaders
    
    func loadShaders()
    {
        shaderProgram = ShaderProgram()
        if shaderProgram!.program != 0 {
            shaderProgram!.attachShader("Shader.vsh", withType: GL_VERTEX_SHADER)
            shaderProgram!.attachShader("Shader.fsh", withType: GL_FRAGMENT_SHADER)
            glBindFragDataLocation(shaderProgram!.program, 0, "outColor");
            shaderProgram!.link()
            positionAttribute = shaderProgram!.getAttributeLocation("position")!
            textureCoordinatesAttribute = shaderProgram!.getAttributeLocation("texcoord")!
        }
    }
    
    //MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
    
    func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!)
    {
        let startTime = DispatchTime.now()
        
        if let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        {
            let width = CVPixelBufferGetWidth(imageBuffer)
            let height = CVPixelBufferGetHeight(imageBuffer)
            
            let ciImage = CIImage(cvImageBuffer: imageBuffer)
            let ciContext = CIContext()
            
            if let image = ciContext.createCGImage(ciImage, from: CGRect(x: 0, y: 0, width: width , height: height))
            {
                let imageData = image.dataProvider?.data
                
                // Get the image data, dimensions, and number of components.
                let data = CFDataGetBytePtr(imageData)
                let numComponents = (image.bitsPerPixel) / 8
                
                // Determine the GL texture format based on the number of components.
                var format: GLint
                switch numComponents
                {
                case 1: format = GL_RED
                case 3: format = GL_RGB
                case 4: format = GL_RGBA
                default: format = GL_RGB
                }
                
                // Generate and bind texture.
                var textureId: GLuint = 0
                glGenTextures(1, &textureId)
                glBindTexture(GLenum(GL_TEXTURE_2D), textureId)
                
                // Set parameters.
                glPixelStorei(GLenum(GL_UNPACK_ALIGNMENT), 1)
                glTexParameterf(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_S), GLfloat(GL_CLAMP_TO_EDGE));
                glTexParameterf(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_WRAP_T), GLfloat(GL_CLAMP_TO_EDGE));
                glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MAG_FILTER), GL_LINEAR)
                glTexParameteri(GLenum(GL_TEXTURE_2D), GLenum(GL_TEXTURE_MIN_FILTER), GL_LINEAR)
                
                // Set the texture data.
                glTexImage2D(GLenum(GL_TEXTURE_2D), 0, format, GLsizei(width), GLsizei(height), 0, GLenum(format), GLenum(GL_UNSIGNED_BYTE), data)

                render()
                
                let timeAfterRendering = DispatchTime.now()
                
                let pixels = UnsafeMutableRawPointer.allocate(bytes: width*height*numComponents, alignedTo: 1)
                glReadPixels(0, 0, GLsizei(width), GLsizei(height), GLenum(format), GLenum(GL_UNSIGNED_BYTE), pixels)
                
                let timeAfterReadingPixels = DispatchTime.now()
                
                let totalTime = (timeAfterReadingPixels.uptimeNanoseconds - startTime.uptimeNanoseconds) / 1_000_000 //milliseconds
                let timeForRendering = (timeAfterRendering.uptimeNanoseconds - startTime.uptimeNanoseconds) / 1_000_000 //milliseconds
                let timeForReadingPixels = (timeAfterReadingPixels.uptimeNanoseconds - timeAfterRendering.uptimeNanoseconds) / 1_000_000 //milliseconds
                
                Swift.print("Frame processed in \(totalTime) ms (rendering: \(timeForRendering) ms, reading pixels: \(timeForReadingPixels) ms)")
            }
        }
    }
}

