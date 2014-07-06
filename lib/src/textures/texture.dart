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

/**
 * A texture stores the information that represents an image or part of an
 * image. It cannot be added to the display list directly. To do this use
 * [Sprite]. If no frame is provided then the whole image is used.
 */
class Texture extends EventTarget {
  static Map<String, Texture> _cache = new Map<String, Texture>();
  static List<Texture> _frameUpdates = new List<Texture>();

  bool noFrame = false;

  /// The base texture of that this texture uses.
  final BaseTexture baseTexture;

  /// The frame specifies the region of the base texture that this texture uses.
  Rectangle<int> frame;

  /// The trim rectangle.
  Rectangle<int> trim;

  TextureUvs _uvs;
  int _width, _height;
  bool _updateFrame = false;

  Texture(this.baseTexture, [Rectangle<int> frame]) {
    if (frame == null) {
      noFrame = true;
      frame = new Rectangle<int>(0, 0, 1, 1);
    }

    this.frame = frame;

    if (baseTexture.hasLoaded) {
      if (noFrame) {
        frame = new Rectangle<int>(0, 0, baseTexture.width, baseTexture.height);
      }

      setFrame(frame);
    } else {
      baseTexture.addEventListener('loaded', _onBaseTextureLoaded);
    }
  }

  /**
   * Returns a texture based on an image url.
   * If the image is not in the texture cache it will be  created and loaded.
   */
  factory Texture.fromImage(String imageUrl, [bool crossorigin, ScaleModes<int>
      scaleMode]) {
    var texture = Texture._cache[imageUrl];

    if (texture == null) {
      texture = new Texture(new BaseTexture.fromImage(imageUrl, crossorigin,
          scaleMode));
      Texture._cache[imageUrl] = texture;
    }

    return texture;
  }

  /**
   * Returns a texture based on a frame id.
   * If the frame id is not in the texture cache a [StateError] will be thrown.
   */
  factory Texture.fromFrame(String frameId) {
    var texture = Texture._cache[frameId];

    if (texture == null) {
      throw new StateError(
          'The frameId "$frameId" does not exist in the texture cache.');
    }

    return texture;
  }

  /**
   * Returns a texture based on a canvas element.
   * If the canvas is not in the texture cache it will be created and loaded.
   */
  factory Texture.fromCanvas(CanvasElement canvas, [ScaleModes<int> scaleMode])
      {
    var baseTexture = new BaseTexture.fromCanvas(canvas, scaleMode);
    return new Texture(baseTexture);
  }

  /// The with of the render texture.
  int get width => _width;

  /// The height of the render texture.
  int get height => _height;

  /// Called when the base texture is loaded.
  void _onBaseTextureLoaded(CustomEvent event) {
    // TODO: why does the JavaScript code removes the 'this.onLoaded' listener?
    baseTexture.removeEventListener('loaded', _onBaseTextureLoaded);

    if (noFrame) {
      frame = new Rectangle<int>(0, 0, baseTexture.width, baseTexture.height);
    }

    setFrame(frame);

    dispatchEvent(new CustomEvent('update', detail: this));
  }

  /// Stream of update events handled by this [Texture].
  CustomEventStream<CustomEvent> get onUpdate {
    _events._eventStream.putIfAbsent('update', () =>
        new CustomEventStream<CustomEvent>(this, 'update', false));
    return _events['type'];
  }

  /// Destroys this texture.
  void destroy([bool destroyBase = false]) {
    if (destroyBase) baseTexture.destroy();
  }

  /// Specifies the rectangle region of the baseTexture.
  void setFrame(Rectangle<int> frame) {
    this.frame = frame;
    _width = frame.width;
    _height = frame.height;

    if (frame.left + frame.width > baseTexture.width || frame.top + frame.height
        > baseTexture.height) {
      throw new StateError(
          'Texture Error: frame does not fit inside the base Texture dimensions.');
    }

    _updateFrame = true;

    Texture._frameUpdates.add(this);
  }

  void _updateWebGLuvs() {
    if (_uvs == null) _uvs = new TextureUvs();

    var tw = baseTexture.width;
    var th = baseTexture.height;

    this._uvs.x0 = frame.left / tw;
    this._uvs.y0 = frame.top / th;

    this._uvs.x1 = (frame.left + frame.width) / tw;
    this._uvs.y1 = frame.top / th;

    this._uvs.x2 = (frame.left + frame.width) / tw;
    this._uvs.y2 = (frame.top + frame.height) / th;

    this._uvs.x3 = frame.left / tw;
    this._uvs.y3 = (frame.top + frame.height) / th;
  }

  /// Adds a texture to the textureCache.
  static void addTextureToCache(Texture texture, String id) {
    Texture._cache[id] = texture;
  }

  /// Remove a texture from the textureCache.
  static Texture removeTextureFromCache(String id) => Texture._cache.remove(id);
}
