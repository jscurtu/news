/*
 * post.vala
 * This file is part of news
 *
 * Copyright (C) 2017 - Günther Wutz
 *
 * news is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * news is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with news. If not, see <http://www.gnu.org/licenses/>.
 */

using Tracker;
namespace News {
    public class Post : Object {
        //public Thumb thumbnailer = new Thumb ();
    
        public signal void thumb_ready ();
    
        public string title { get; set; }
        public string content { get; set; }
        public string url { get; set; }
        public string author { get; set; }
        public string thumbnail { get; set; }
        public bool starred { get; set; }
        public bool read { get; set; }
        public bool thumb_exists = false;
        
        public Post (HashTable<string, Value?> data) {
            this.title = (string)data.get ("title");
            this.content = (string)data.get ("content");
            this.url = (string)data.get ("url");
            this.author = (string)data.get ("fullname");
            this.read = (bool)data.get ("is_read");
            this.starred = (bool)data.get ("is_starred");
            
            this.thumbnail = News.UI.Application.CACHE + compute_hash () + ".png";
            if (!FileUtils.test (this.thumbnail, FileTest.EXISTS)) {
                Idle.add (() => {
                    generate_thumbnail ();
                    return false;
                });
            } else {
                thumb_exists = true;
            }
        }
    
        private string compute_hash () {
            return Checksum.compute_for_string (ChecksumType.MD5, this.url);
        }
        
        // Thumbnail shit
        private WebKit.WebView webview;
        
        public void generate_thumbnail () {
            this.webview = new WebKit.WebView ();
            this.webview.sensitive = false;
            this.webview.load_changed.connect (draw_thumbnail);
            var author = this.author != null ? this.author : "";
            this.webview.load_html("""
                <div style="width: 250px">
                <h3 style="margin-bottom: 2px">%s</h3>
                <small style="color: #333">%s</small>
                <small style="color: #9F9F9F">%s</small>
                </div>
            """.printf (title, author, content), null);
        }
        
        private void draw_thumbnail (WebKit.LoadEvent event) {
            if (event == WebKit.LoadEvent.FINISHED) {
                print ("thumb: %s\n", thumbnail);
                this.webview.get_snapshot.begin (WebKit.SnapshotRegion.FULL_DOCUMENT,
                                                 WebKit.SnapshotOptions.NONE,
                                                 null, 
                                                 (obj, res) => {
                    try {
                        var surface = this.webview.get_snapshot.end(res);
                        var new_surface = new Cairo.ImageSurface (Cairo.Format.ARGB32, 256, 256);
                        var ctx = new Cairo.Context(new_surface);
                        ctx.set_source_surface(surface, 0, 0);
                        ctx.paint ();
                        new_surface.write_to_png (thumbnail);
                        thumb_ready ();
                    } catch (Error e) {
                        error (e.message);
                    }
                    
                });
            }
        }
    }
}