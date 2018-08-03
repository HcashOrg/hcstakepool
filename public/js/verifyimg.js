$(function(){

                    $(function(){

                        alert(1)
   
                        $.ajax({
                            type: "POST",
                            url:'/api/getCaptcha',
                            contentType: "image/png",
                            data:"",
                            success: function(data){
                                alert("return data")
                            $('#test').html('<img src="' + data.data + '" />');
                            //('<img src="data:image/png;base64,' + data + '" />');
                         },
                    
                           } );
                    
                    });

});