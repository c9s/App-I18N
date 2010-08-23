

function writeAll(e) {
    var msgids = jQuery(e).parents("form").find( "*[name=msgid[]]" )
        .map( function(i,n) {
            return jQuery(n).val();
         }).get();

    var msgstrs = jQuery(e).parents("form").find( "textarea[name=msgstr[]]" )
        .map( function(i,n) {
            return jQuery(n).val();
         }).get();

    var pofile = jQuery(e).parents("form").find( "input[name=pofile]" ).val();
    //console.log( pofile , msgids , msgstrs );
    jQuery.ajax({
        url: '/',
        type: 'post',
        data: {
            'msgid[]': msgids,
            'msgstr[]': msgstrs,
            'pofile': pofile
         },
        success: function( ) { 
            jQuery.jGrowl( "Updated" );
         }
     });
    return false;
}


