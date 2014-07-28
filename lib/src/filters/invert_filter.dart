// Copyright 2014 Federico Omoto
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

part of pixi;

/// This inverts your displayObjects colors.
class InvertFilter extends Filter {
  InvertFilter() {
    // Set the uniforms.
    _uniforms.add(new Uniform1f('invert', 1.0));

    _fragmentSrc =
        '''
        precision mediump float;
        varying vec2 vTextureCoord;
        varying vec4 vColor;
        uniform float invert;
        uniform sampler2D uSampler;

        void main(void) {
          gl_FragColor = texture2D(uSampler, vTextureCoord);
          gl_FragColor.rgb = mix((vec3(1) - gl_FragColor.rgb) * gl_FragColor.a, gl_FragColor.rgb, 1.0 - invert);
        }''';
  }

  /// Returns the strength of the invert.
  double get invert => (_uniforms.first as Uniform1f).x;

  /**
   * Sets the strength of the invert. 1 will fully invert the colors, 0 will
   * make the object its normal color.
   */
  void set invert(double value) {
    (_uniforms.first as Uniform1f).x = value;
  }
}
