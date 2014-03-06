# Used to test the performance of various strategies for adding the html for the gallery
# and attaching event hanlders. Delete when we are done.

class window.GalleryLoadingTest
  
  constructor: (occasion) ->
    @occasion = Occasion.normalize_to_object(occasion)
    @photos_node = $("#gallery2 .photos")
    @loaded_ids = []
   
  @click_handler: (photo) => 
    alert photo
   
  load_all: => 
    # photo_blocks = ""
    # t0 = now()
    # photo_blocks += (new PhotoBlockView photo).flat_photo_block() for photo in Photo.all()
    # t1 = now()
    # @photos_node.get(0).innerHTML = photo_blocks
    # t2 = now()
    # console.log "time to create photos html as string: #{t1-t0}"
    # console.log "time to insert photos html as string: #{t2-t1}"
       
    # photo_blocks = ""
    # t0 = now()
    # photo_blocks += (new PhotoBlockView photo).flat_photo_block_stripped() for photo in Photo.all()
    # t1 = now()
    # @photos_node.get(0).innerHTML = photo_blocks
    # t2 = now()
    # console.log "time to create photos html as stripped string: #{t1-t0}"
    # console.log "time to insert photos html as stripped string: #{t2-t1}"
        
    # photo_blocks = ""
    # t0 = now()
    # photo_blocks += (new PhotoBlockView photo).flat_photo_block() for photo in Photo.all()
    # t1 = now()
    # @photos_node.get(0).innerHTML = photo_blocks
    # t2 = now()
    # console.log "time to create photos html as string no white space: #{t1-t0}"
    # console.log "time to insert photos html as string no white space: #{t2-t1}"
    
    # t0 = now()
    # photo_blocks = Photo.all().map (photo) -> (new PhotoBlockView photo).photo_block()
    # t1 = now()
    # @photos_node.html photo_blocks
    # t2 = now()
    # console.log "time to create photos html as jquery elements: #{t1-t0}"
    # console.log "time to insert photos html as jquery elements: #{t2-t1}"
    
    # photo_blocks = ""
    # t0 = now()
    # photo_blocks += (new PhotoBlockView photo).flat_photo_block_no_white_space() for photo in Photo.all()
    # t1 = now()
    # @photos_node.get(0).innerHTML = photo_blocks
    # t2 = now()
    # $(li).on("click", GalleryHandler2.click_handler) for li in @photos_node.find("li")
    # t3 = now()
    # console.log "time to create photos html as string no white space without click_handler: #{t1-t0}"
    # console.log "time to insert photos html as string no white space without click_handler: #{t2-t1}"
    # console.log "time to add click handler using on: #{t3-t2}"
    
    photo_blocks = ""
    t0 = now()
    photo_blocks += (new PhotoBlockView photo).flat_photo_block_no_white_space_w_click() for photo in Photo.all()
    t1 = now()
    @photos_node.get(0).innerHTML = photo_blocks
    t2 = now()
    console.log "time to create photos html as string no white space without click_handler: #{t1-t0}"
    console.log "time to insert photos html as string no white space without click_handler: #{t2-t1}"
    
    
class window.PhotoBlockView
  
  constructor: (photo) ->
    @photo = photo
 
  photo_block: =>
    $("<li class='photo_block'></li>").html [@title_block_html(), @photo_html(), @comments_block_html()]
     
  title_block_html: => 
    $("<div class='title_block'>
        <div class='caption'>#{@photo.caption}</div>
        <div class='creator'>By <span class='creator'>#{full_name(@photo.creator)}</span></div>
       </div>")

  photo_html: => 
    $("<img class='photo' src='#{@photo.thumb_display_url()}'>")
      
  comments_block_html: =>
    $("<div class='comments'>#{"Some comments <br/>" for n in [0..10]}</div>")
      
  
  flat_photo_block: => 
    "<li class='photo_block'>
       <div class='title_block'>
         <div class='caption'>#{@photo.caption}</div>
         <div class='creator'>By <span class='creator'>#{full_name(@photo.creator)}</span></div>
         <img class='photo' src='#{@photo.thumb_display_url()}'>
         <div class='comments'>#{"Some comments <br/>" for n in [0..10]}</div>
       </div>
     </li>"
  
  flat_photo_block_stripped: => 
    "<li class='photo_block'>
       <div class='title_block'>
         <div class='caption'>#{@photo.caption}</div>
         <div class='creator'>By <span class='creator'>#{full_name(@photo.creator)}</span></div>
         <img class='photo' src='#{@photo.thumb_display_url()}'>
         <div class='comments'>#{"Some comments <br/>" for n in [0..10]}</div>
       </div>
     </li>".replace(/\n/g, "").replace(/>\s+/g, ">").replace(/^\s+/g, "")

  flat_photo_block_no_white_space: => 
   "<li class='photo_block'><div class='title_block'><div class='caption'>#{@photo.caption}</div><div class='creator'>By <span class='creator'>#{full_name(@photo.creator)}</span></div><img class='photo' src='#{@photo.thumb_display_url()}'><div class='comments'>#{"Some comments <br/>" for n in [0..10]}</div></div></li>"
      
  flat_photo_block_no_white_space_w_click: => 
   "<li class='photo_block' onclick='GalleryHandler2.click_handler(#{@photo.id})'><div class='title_block'><div class='caption'>#{@photo.caption}</div><div class='creator'>By <span class='creator'>#{full_name(@photo.creator)}</span></div><img class='photo' src='#{@photo.thumb_display_url()}'><div class='comments'>#{"Some comments <br/>" for n in [0..10]}</div></div></li>"
