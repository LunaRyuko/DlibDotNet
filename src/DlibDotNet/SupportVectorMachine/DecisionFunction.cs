﻿using System;
using System.IO;
using DlibDotNet.Extensions;

// ReSharper disable once CheckNamespace
namespace DlibDotNet
{

    public sealed class DecisionFunction<TScalar, TKernel> : DlibObject
        where TScalar : struct
        where TKernel : KernelBase
    {

        #region Fields

        private readonly KernelBaseParameter _Parameter;

        #endregion

        #region Constructors

        internal DecisionFunction(IntPtr ptr,
                                  KernelBaseParameter parameter,
                                  bool isEnabledDispose = true) :
            base(isEnabledDispose)
        {
            this._Parameter = parameter;
            this.NativePtr = ptr;
        }

        #endregion

        #region Methods

        public static DecisionFunction<TScalar, TKernel> Deserialize(string path, int templateRows, int templateColumns)
        {
            if (path == null)
                throw new ArgumentNullException(nameof(path));
            if (!File.Exists(path))
                throw new FileNotFoundException($"{path} is not found", path);

            KernelFactory.TryParse<TScalar>(out MatrixElementTypes sampleType);
            KernelFactory.TryParse<TKernel>(out SvmKernelType kernelType);

            var param = new KernelBaseParameter(kernelType, sampleType, templateRows, templateColumns);

            var str = Dlib.Encoding.GetBytes(path);
            var strLength = str.Length;
            Array.Resize(ref str, strLength + 1);
            str[strLength] = (byte)'\0';
            var error = NativeMethods.deserialize_decision_function(str,
                                                                    kernelType.ToNativeKernelType(),
                                                                    sampleType.ToNativeMatrixElementType(),
                                                                    templateRows,
                                                                    templateColumns,
                                                                    out var ret,
                                                                    out var errorMessage);

            switch (error)
            {
                case NativeMethods.ErrorType.GeneralSerialization:
                    throw new SerializationException(StringHelper.FromStdString(errorMessage, true));
                case NativeMethods.ErrorType.MatrixElementTypeNotSupport:
                    throw new ArgumentException($"{param.SampleType} is not supported.");
                case NativeMethods.ErrorType.MatrixElementTemplateSizeNotSupport:
                    throw new ArgumentException($"{nameof(param.TemplateColumns)} or {nameof(param.TemplateRows)} is not supported.");
                case NativeMethods.ErrorType.SvmKernelNotSupport:
                    throw new ArgumentException($"{param.KernelType} is not supported.");
            }

            return new DecisionFunction<TScalar, TKernel>(ret, param);
        }

        public static void Serialize(DecisionFunction<TScalar, TKernel> function, string path)
        {
            if (function == null)
                throw new ArgumentNullException(nameof(function));
            if (string.IsNullOrEmpty(path))
                throw new ArgumentException();

            function.ThrowIfDisposed();

            var str = Dlib.Encoding.GetBytes(path);
            var strLength = str.Length;
            Array.Resize(ref str, strLength + 1);
            str[strLength] = (byte)'\0';
            var ret = NativeMethods.serialize_decision_function(function._Parameter.KernelType.ToNativeKernelType(),
                                                                function._Parameter.SampleType.ToNativeMatrixElementType(),
                                                                function._Parameter.TemplateRows,
                                                                function._Parameter.TemplateColumns,
                                                                function.NativePtr,
                                                                str,
                                                                out var errorMessage);

            switch (ret)
            {
                case NativeMethods.ErrorType.GeneralSerialization:
                    throw new SerializationException(StringHelper.FromStdString(errorMessage, true));
                case NativeMethods.ErrorType.MatrixElementTypeNotSupport:
                    throw new ArgumentException($"{function._Parameter.SampleType} is not supported.");
                case NativeMethods.ErrorType.MatrixElementTemplateSizeNotSupport:
                    throw new ArgumentException($"{nameof(function._Parameter.TemplateColumns)} or {nameof(function._Parameter.TemplateRows)} is not supported.");
                case NativeMethods.ErrorType.SvmKernelNotSupport:
                    throw new ArgumentException($"{function._Parameter.KernelType} is not supported.");
            }
        }

        #region Overrides 

        /// <summary>
        /// Releases all unmanaged resources.
        /// </summary>
        protected override void DisposeUnmanaged()
        {
            base.DisposeUnmanaged();

            if (this.NativePtr == IntPtr.Zero)
                return;

            NativeMethods.decision_function_delete(this._Parameter.KernelType.ToNativeKernelType(),
                                                   this._Parameter.SampleType.ToNativeMatrixElementType(),
                                                   this._Parameter.TemplateRows,
                                                   this._Parameter.TemplateColumns,
                                                   this.NativePtr);
        }

        #endregion

        #endregion

    }

}
