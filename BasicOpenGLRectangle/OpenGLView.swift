//
//  OpenGLView.swift
//  BasicOpenGLRectangle
//
//  Created by Krzysztof Deneka on 04.08.2017.
//  Copyright © 2017 biz.blastar. All rights reserved.
//

import Foundation
import UIKit
import QuartzCore
import OpenGLES
import GLKit

class OpenGLView: UIView {
    
    let vertices: Array<GLfloat> = [
        -1.0, -1.0, 0.0,
        -1.0, 1.0, 0.0,
        1.0, 1.0, 0.0,
        1.0, 1.0, 0.0,
        1.0, -1.0, 0.0,
        -1.0, -1.0, 0.0
    ]
    
    var _eaglLayer: CAEAGLLayer?
    var _context: EAGLContext?
    var _depthRenderBuffer = GLuint()
    var _colorRenderBuffer = GLuint()
    
    var rectangleAttr = GLuint()
    
    var vertexArray: GLuint = 0
    var vertexBuffer: GLuint = 0
    
    override class var layerClass: AnyClass {
        get {
            return CAEAGLLayer.self
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        if (self.setupLayer() != 0) {
            NSLog("OpenGLView init():  setupLayer() failed")
            return
        }
        if (self.setupContext() != 0) {
            NSLog("OpenGLView init():  setupContext() failed")
            return
        }
        if (self.setupDepthBuffer() != 0) {
            NSLog("OpenGLView init():  setupDepthBuffer() failed")
            return
        }
        if (self.setupRenderBuffer() != 0) {
            NSLog("OpenGLView init():  setupRenderBuffer() failed")
            return
        }
        if (self.setupFrameBuffer() != 0) {
            NSLog("OpenGLView init():  setupFrameBuffer() failed")
            return
        }
        if (self.compileShaders() != 0) {
            NSLog("OpenGLView init():  compileShaders() failed")
            return
        }
        if (self.setupVBOs() != 0) {
            NSLog("OpenGLView init():  setupVBOs() failed")
            return
        }
        if (self.setupDisplayLink() != 0) {
            NSLog("OpenGLView init():  setupDisplayLink() failed")
        }
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("OpenGLView init(coder:) has not been implemented")
    }
    
    func setupLayer() -> Int {
        _eaglLayer = self.layer as? CAEAGLLayer
        if (_eaglLayer == nil) {
            NSLog("setupLayer:  _eaglLayer is nil")
            return -1
        }
        _eaglLayer!.isOpaque = true
        return 0
    }
    
    func setupContext() -> Int {
        let api : EAGLRenderingAPI = EAGLRenderingAPI.openGLES2
        _context = EAGLContext(api: api)
        
        if (_context == nil) {
            NSLog("Failed to initialize OpenGLES 2.0 context")
            return -1
        }
        if (!EAGLContext.setCurrent(_context)) {
            NSLog("Failed to set current OpenGL context")
            return -1
        }
        return 0
    }
    
    func setupDepthBuffer() -> Int {
        glGenRenderbuffers(1, &_depthRenderBuffer);
        glBindRenderbuffer(GLenum(GL_RENDERBUFFER), _depthRenderBuffer);
        glRenderbufferStorage(GLenum(GL_RENDERBUFFER), GLenum(GL_DEPTH_COMPONENT16), GLsizei(self.frame.size.width), GLsizei(self.frame.size.height))
        return 0
    }
    
    func setupFrameBuffer() -> Int {
        var framebuffer: GLuint = 0
        glGenFramebuffers(1, &framebuffer)
        glBindFramebuffer(GLenum(GL_FRAMEBUFFER), framebuffer)
        glFramebufferRenderbuffer(GLenum(GL_FRAMEBUFFER), GLenum(GL_COLOR_ATTACHMENT0),
                                  GLenum(GL_RENDERBUFFER), _colorRenderBuffer)
        glFramebufferRenderbuffer(GLenum(GL_FRAMEBUFFER), GLenum(GL_DEPTH_ATTACHMENT), GLenum(GL_RENDERBUFFER), _depthRenderBuffer);
        return 0
    }
    
    func setupRenderBuffer() -> Int {
        glGenRenderbuffers(1, &_colorRenderBuffer)
        glBindRenderbuffer(GLenum(GL_RENDERBUFFER), _colorRenderBuffer)
        
        if (_context == nil) {
            NSLog("setupRenderBuffer():  _context is nil")
            return -1
        }
        if (_eaglLayer == nil) {
            NSLog("setupRenderBuffer():  _eagLayer is nil")
            return -1
        }
        if (_context!.renderbufferStorage(Int(GL_RENDERBUFFER), from: _eaglLayer!) == false) {
            NSLog("setupRenderBuffer():  renderbufferStorage() failed")
            return -1
        }
        return 0
    }
    
    func setupVBOs() -> Int {
        
        glGenVertexArrays(1, &vertexArray)
        glBindVertexArray(vertexArray)
        
        glGenBuffers(1, &vertexBuffer)
        glBindBuffer(GLenum(GL_ARRAY_BUFFER), vertexBuffer)
        
        glBufferData(GLenum(GL_ARRAY_BUFFER), vertices.count * MemoryLayout<GLfloat>.size, vertices, GLenum(GL_STATIC_DRAW))

        return 0
    }
    
    func setupDisplayLink() -> Int {
        let displayLink : CADisplayLink = CADisplayLink(target: self, selector: #selector(OpenGLView.render(displayLink:)))
        displayLink.add(to: RunLoop.current, forMode: RunLoopMode(rawValue: RunLoopMode.defaultRunLoopMode.rawValue))
        return 0
    }
    
    func compileShader(shaderName: String, shaderType: GLenum, shader: UnsafeMutablePointer<GLuint>) -> Int {
        let shaderPath = Bundle.main.path(forResource: shaderName, ofType:"glsl")
        var error : NSError?
        let shaderString: NSString?
        do {
            shaderString = try NSString(contentsOfFile: shaderPath!, encoding:String.Encoding.utf8.rawValue)
        } catch let error1 as NSError {
            error = error1
            shaderString = nil
        }
        if error != nil {
            NSLog("OpenGLView compileShader():  error loading shader: %@", error!.localizedDescription)
            return -1
        }
        
        shader.pointee = glCreateShader(shaderType)
        if (shader.pointee == 0) {
            NSLog("OpenGLView compileShader():  glCreateShader failed")
            return -1
        }
        var shaderStringUTF8 = shaderString!.utf8String
        var shaderStringLength: GLint = GLint(Int32(shaderString!.length))
        glShaderSource(shader.pointee, 1, &shaderStringUTF8, &shaderStringLength)
        
        glCompileShader(shader.pointee);
        var success = GLint()
        glGetShaderiv(shader.pointee, GLenum(GL_COMPILE_STATUS), &success)
        
        if (success == GL_FALSE) {
            let infoLog = UnsafeMutablePointer<GLchar>.allocate(capacity: 256)
            var infoLogLength = GLsizei()
            
            glGetShaderInfoLog(shader.pointee, GLsizei(MemoryLayout<GLchar>.size * 256), &infoLogLength, infoLog)
            NSLog("OpenGLView compileShader():  glCompileShader() failed:  %@", String(cString: infoLog))
            
            infoLog.deallocate(capacity: 256)
            return -1
        }
        
        return 0
    }
    
    func compileShaders() -> Int {
        let vertexShader = UnsafeMutablePointer<GLuint>.allocate(capacity: 1)
        if (self.compileShader(shaderName: "SimpleVertex", shaderType: GLenum(GL_VERTEX_SHADER), shader: vertexShader) != 0 ) {
            NSLog("OpenGLView compileShaders():  compileShader() failed")
            return -1
        }
        let fragmentShader = UnsafeMutablePointer<GLuint>.allocate(capacity: 1)
        if (self.compileShader(shaderName: "SimpleFragment", shaderType: GLenum(GL_FRAGMENT_SHADER), shader: fragmentShader) != 0) {
            NSLog("OpenGLView compileShaders():  compileShader() failed")
            return -1
        }
        
        let program = glCreateProgram()
        glAttachShader(program, vertexShader.pointee)
        glAttachShader(program, fragmentShader.pointee)
        glLinkProgram(program)
        
        var success = GLint()
        
        glGetProgramiv(program, GLenum(GL_LINK_STATUS), &success)
        if (success == GL_FALSE) {
            let infoLog = UnsafeMutablePointer<GLchar>.allocate(capacity: 1024)
            var infoLogLength = GLsizei()
            
            glGetProgramInfoLog(program, GLsizei(MemoryLayout<GLchar>.size * 1024), &infoLogLength, infoLog)
            NSLog("OpenGLView compileShaders():  glLinkProgram() failed:  %@", String(cString:  infoLog))
            
            infoLog.deallocate(capacity: 1024)
            fragmentShader.deallocate(capacity: 1)
            vertexShader.deallocate(capacity: 1)
            
            return -1
        }
        
        glUseProgram(program)
        
        rectangleAttr = GLuint(glGetAttribLocation(program, "Position"))
        
        fragmentShader.deallocate(capacity: 1)
        vertexShader.deallocate(capacity: 1)
        
        return 0
    }
    
    func render(displayLink: CADisplayLink) -> Int {
        glClearColor(0.0/255.0, 0.0/255.0, 120.0/255.0, 1.0)
        glClear(GLbitfield(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT))
        glEnable(GLenum(GL_DEPTH_TEST))
        
        glViewport(0, 0, GLsizei(self.frame.size.width), GLsizei(self.frame.size.height))
        
        glEnableVertexAttribArray(rectangleAttr)
        glVertexAttribPointer(rectangleAttr, 3, GLenum(GL_FLOAT), GLboolean(GL_FALSE), 0, UnsafePointer<GLfloat>(bitPattern:0))
        
        
        glDrawArrays(GLenum(GL_TRIANGLES), 0, GLsizei(vertices.count/3))
        
        glDisableVertexAttribArray(rectangleAttr)
        
        _context!.presentRenderbuffer(Int(GL_RENDERBUFFER))
        return 0
    }
    
}
