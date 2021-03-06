﻿using System.Runtime.InteropServices;
using DlibDotNet;
using OpenCvSharp;

namespace MatToMatrix
{

    internal class Program
    {

        private static void Main()
        {
            using (var mat = Cv2.ImRead("Lenna.png", ImreadModes.AnyColor))
            {
                var array = new byte[mat.Width * mat.Height * mat.ElemSize()];
                Marshal.Copy(mat.Data, array, 0, array.Length);

                // TODO: support BGR image
                using (var win = new ImageWindow())
                using (var image = new Matrix<RgbPixel>(array, mat.Height, mat.Width, mat.ElemSize()))
                {
                    // Display it all on the screen
                    win.ClearOverlay();
                    win.SetImage(image);

                    win.WaitUntilClosed();
                }
            }
        }

    }

}